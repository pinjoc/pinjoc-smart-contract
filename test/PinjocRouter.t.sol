// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {PinjocRouter} from "../src/PinjocRouter.sol";
import {IMockGTXOBLending} from "../src/interfaces/IMockGTXOBLending.sol";
import {MockGTXOBLending} from "../src/mocks/MockGTXOBLending.sol";
import {LendingPoolManager} from "../src/LendingPoolManager.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {PinjocToken} from "../src/PinjocToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {LendingOrderType} from "../src/types/Types.sol";
import {Side, Status} from "../src/types/Types.sol";

contract PinjocRouterBaseTest is Test {

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    PinjocRouter pinjocRouter;
    MockOracle wethUsdcOracle;
    LendingPoolManager public lendingPoolManager;
    LendingPool public lendingPool;
    MockGTXOBLending orderBook;

    address owner = makeAddr("owner");

    address lender = makeAddr("lender");
    uint256 lenderDefaultBalance = 2000e6; // 1000USDC

    address borrower = makeAddr("borrower");
    uint256 borrowerDefaultCollateral = 1e18; // 1WETH = 2500USDC

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/Ea4M-V84UObD22z2nNlwDD9qP8eqZuSI");
        
        wethUsdcOracle = new MockOracle(weth, usdc);
        wethUsdcOracle.setPrice(2500e6); // 1 WETH = 2500USDC

        lendingPoolManager = new LendingPoolManager();
        lendingPoolManager.setLtv(90e16); // SET LOAN TO VALUE TO 90%
        
        pinjocRouter = new PinjocRouter(address(lendingPoolManager));
        pinjocRouter.createOrderBook(usdc, weth, "MAY", 2025);

        orderBook = MockGTXOBLending(pinjocRouter.getOrderBookAddress(usdc, weth, "MAY", 2025));

        lendingPool = LendingPool(
            lendingPoolManager.createLendingPool(
                address(pinjocRouter),
                usdc,
                weth,
                5e16, // 5% RATE APY
                block.timestamp + 90 days,
                "MAY",
                2025,
                address(wethUsdcOracle)
            )
        );

        deal(usdc, lender, lenderDefaultBalance); // 1000USDC
        deal(weth, borrower, borrowerDefaultCollateral); // 1 WETH = 2500USDC
    }

    function setUp_LendOrder(uint256 lendingAmount) public {
        vm.startPrank(lender);
        IERC20(usdc).approve(address(pinjocRouter), lenderDefaultBalance);
        pinjocRouter.placeOrder(
            usdc,
            weth,
            lendingAmount,
            0,
            5e16, // 5% APY
            block.timestamp + 90 days,
            "MAY",
            2025,
            LendingOrderType.LEND
        );
        vm.stopPrank();
    }

    function setUp_BorrowOrder(uint256 borrowAmount, uint256 collateralAmount) public {
        vm.startPrank(borrower);
        IERC20(weth).approve(address(pinjocRouter), borrowerDefaultCollateral);
        pinjocRouter.placeOrder(
            usdc,
            weth,
            borrowAmount, // 90% of 1 WETH = 2500USDC
            collateralAmount,
            5e16, // 5% APY
            block.timestamp + 90 days,
            "MAY",
            2025,
            LendingOrderType.BORROW
        );
        vm.stopPrank();
    }
}

contract PinjocRouterPlaceOrderFlowTest is PinjocRouterBaseTest {

    function test_LendOrder() public {
        uint256 lendAmount = 1000e6; // 1000USDC

        setUp_LendOrder(lendAmount);

        (, address trader, uint256 amount, , , , Status status) = orderBook.orderQueue(5e16, Side.BUY, 0);
        assertEq(trader, lender);
        assertEq(amount, lendAmount);
        assertEq(uint256(status), uint256(Status.OPEN));

        assertEq(IERC20(usdc).balanceOf(lender), lenderDefaultBalance - lendAmount);
    }

    function test_BorrowOrder() public {
        uint256 borrowAmount = 1000e6; // 1000USDC
        uint256 collateralAmount = 1e18; // 1WETH = 2500USDC

        setUp_BorrowOrder(borrowAmount, collateralAmount);

        (, address trader, uint256 amount, uint256 collateral, , , Status status) = orderBook.orderQueue(5e16, Side.SELL, 0);
        assertEq(trader, borrower);
        assertEq(amount, borrowAmount);
        assertEq(collateral, collateralAmount);
        assertEq(uint256(status), uint256(Status.OPEN));

        assertEq(IERC20(weth).balanceOf(borrower), borrowerDefaultCollateral - collateralAmount);
    }

    function test_PlaceOrder_BothMatchedFully() public {
        uint256 borrowAmount = 1000e6; // 1000USDC
        uint256 collateralAmount = 1e18; // 1WETH = 2500USDC

        setUp_BorrowOrder(borrowAmount, collateralAmount);
        setUp_LendOrder(borrowAmount);
        
        // Check borrower balance
        assertEq(IERC20(usdc).balanceOf(borrower), borrowAmount);
        assertEq(IERC20(weth).balanceOf(borrower), borrowerDefaultCollateral - collateralAmount);

        // Check borrower data on lending pool
        assertEq(lendingPool.totalBorrowAssets(), borrowAmount);
        assertEq(lendingPool.totalBorrowShares(), borrowAmount);
        assertEq(lendingPool.userBorrowShares(borrower), borrowAmount);
        assertEq(lendingPool.userCollaterals(borrower), collateralAmount);

        // Check lender balance
        assertEq(IERC20(lendingPool.pinjocToken()).balanceOf(lender), borrowAmount);
        assertEq(IERC20(usdc).balanceOf(lender), lenderDefaultBalance - borrowAmount);

        // Check lender data on lending pool
        assertEq(lendingPool.totalSupplyAssets(), borrowAmount);
        assertEq(lendingPool.totalSupplyShares(), borrowAmount);
    }

    function test_PlaceOrder_OnlyLendMatchedFully() public {
        uint256 borrowAmount = 2000e6; // 2000USDC
        uint256 collateralAmount = 1e18; // 1WETH = 2500USDC
        uint256 supplyAmount = 1000e6; // 1000USDC

        setUp_BorrowOrder(borrowAmount, collateralAmount);
        setUp_LendOrder(supplyAmount);
        
        // Check borrower balance
        assertEq(IERC20(usdc).balanceOf(borrower), supplyAmount);
        assertEq(IERC20(weth).balanceOf(borrower), borrowerDefaultCollateral - collateralAmount);

        // Check borrower data on lending pool
        assertEq(lendingPool.totalBorrowAssets(), supplyAmount);
        assertEq(lendingPool.totalBorrowShares(), supplyAmount);
        assertEq(lendingPool.userBorrowShares(borrower), supplyAmount);
        assertEq(lendingPool.userCollaterals(borrower), collateralAmount * supplyAmount / borrowAmount);

        // Check borrower order queue
        (, address trader, uint256 amount, , , , Status status) = orderBook.orderQueue(5e16, Side.SELL, 0);
        assertEq(trader, borrower);
        assertEq(amount, borrowAmount * supplyAmount / borrowAmount);
        assertEq(uint256(status), uint256(Status.PARTIALLY_FILLED));

        // Check lender balance
        assertEq(IERC20(lendingPool.pinjocToken()).balanceOf(lender), supplyAmount);
        assertEq(IERC20(usdc).balanceOf(lender), lenderDefaultBalance - supplyAmount);

        // Check lender data on lending pool
        assertEq(lendingPool.totalSupplyAssets(), supplyAmount);
        assertEq(lendingPool.totalSupplyShares(), supplyAmount);
    }

    function test_PlaceOrder_OnlyBorrowMatchedFully() public {
        uint256 borrowAmount = 1000e6; // 1000USDC
        uint256 collateralAmount = 1e18; // 1WETH = 2500USDC
        uint256 supplyAmount = 2000e6; // 2000USDC

        setUp_BorrowOrder(borrowAmount, collateralAmount);
        setUp_LendOrder(supplyAmount);
        
        // Check borrower balance
        assertEq(IERC20(usdc).balanceOf(borrower), borrowAmount);
        assertEq(IERC20(weth).balanceOf(borrower), borrowerDefaultCollateral - collateralAmount);

        // Check borrower data on lending pool
        assertEq(lendingPool.totalBorrowAssets(), borrowAmount);
        assertEq(lendingPool.totalBorrowShares(), borrowAmount);
        assertEq(lendingPool.userBorrowShares(borrower), borrowAmount);
        assertEq(lendingPool.userCollaterals(borrower), collateralAmount);

        // Check lender balance
        assertEq(IERC20(lendingPool.pinjocToken()).balanceOf(lender), borrowAmount);
        assertEq(IERC20(usdc).balanceOf(lender), 0);

        // Check lender data on lending pool
        assertEq(lendingPool.totalSupplyAssets(), borrowAmount);
        assertEq(lendingPool.totalSupplyShares(), borrowAmount);
    }
}

contract PinjocRouterCancelOrderTest is PinjocRouterBaseTest {
    
    function test_CancelLendOrder() public {
        uint256 lendAmount = 1000e6; // 1000USDC

        setUp_LendOrder(lendAmount);

        MockGTXOBLending.Order[] memory userOrders = orderBook.getUserOrders(lender);
        assertEq(userOrders.length, 1);
        assertEq(userOrders[0].trader, lender);
        assertEq(uint256(userOrders[0].status), uint256(Status.OPEN));
        assertEq(IERC20(usdc).balanceOf(lender), lenderDefaultBalance - lendAmount);
        
        vm.startPrank(lender);
        pinjocRouter.cancelOrder(usdc, weth, "MAY", 2025, 0);
        vm.stopPrank();
        
        userOrders = orderBook.getUserOrders(lender);
        assertEq(userOrders.length, 1);
        assertEq(userOrders[0].trader, lender);
        assertEq(uint256(userOrders[0].status), uint256(Status.CANCELLED));
        assertEq(IERC20(usdc).balanceOf(lender), lenderDefaultBalance);
    }

    function test_CancelBorrowOrder() public {
        uint256 borrowAmount = 1000e6; // 1000USDC
        uint256 collateralAmount = 1e18; // 1WETH = 2500USDC

        setUp_BorrowOrder(borrowAmount, collateralAmount);

        MockGTXOBLending.Order[] memory userOrders = orderBook.getUserOrders(borrower);
        assertEq(userOrders.length, 1);
        assertEq(userOrders[0].trader, borrower);
        assertEq(uint256(userOrders[0].status), uint256(Status.OPEN));
        assertEq(IERC20(usdc).balanceOf(borrower), 0);
        assertEq(IERC20(weth).balanceOf(borrower), borrowerDefaultCollateral - collateralAmount);
        
        vm.startPrank(borrower);
        pinjocRouter.cancelOrder(usdc, weth, "MAY", 2025, 0);
        vm.stopPrank();
        
        userOrders = orderBook.getUserOrders(borrower);
        assertEq(userOrders.length, 1);
        assertEq(userOrders[0].trader, borrower);
        assertEq(uint256(userOrders[0].status), uint256(Status.CANCELLED));
        assertEq(IERC20(usdc).balanceOf(borrower), 0);
        assertEq(IERC20(weth).balanceOf(borrower), borrowerDefaultCollateral);
    }
}