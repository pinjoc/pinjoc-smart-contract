// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {PinjocRouter} from "../src/PinjocRouter.sol";
import {IMockGTXOrderBook} from "../src/interfaces/IMockGTXOrderBook.sol";
import {MockGTXOrderBook} from "../src/mocks/MockGTXOrderBook.sol";
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

    address owner = makeAddr("owner");

    address lender = makeAddr("lender");
    uint256 lenderDefaultBalance = 1000e6; // 1000USDC

    address borrower = makeAddr("borrower");
    uint256 borrowerDefaultCollateral = 1e18; // 1WETH = 2500USDC
    uint256 borrowerDefaultBalance = 2000e6; // 2500USDC

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/Ea4M-V84UObD22z2nNlwDD9qP8eqZuSI");
        
        wethUsdcOracle = new MockOracle(weth, usdc);
        wethUsdcOracle.setPrice(2500e6); // 1 WETH = 2500USDC

        lendingPoolManager = new LendingPoolManager();
        lendingPoolManager.setLtv(90e16); // SET LOAN TO VALUE TO 90%
        
        pinjocRouter = new PinjocRouter(address(lendingPoolManager));
        pinjocRouter.createOrderBook(usdc, weth, "MAY", 2025);

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

    function setUp_LendLimitOrder() public {
        vm.startPrank(lender);
        IERC20(usdc).approve(address(pinjocRouter), lenderDefaultBalance);
        pinjocRouter.placeOrder(
            usdc,
            weth,
            lenderDefaultBalance,
            0,
            5e16, // 5% APY
            block.timestamp + 90 days,
            "MAY",
            2025,
            LendingOrderType.LEND
        );
        vm.stopPrank();
    }

    function setUp_BorrowLimitOrder() public {
        vm.startPrank(borrower);
        IERC20(weth).approve(address(pinjocRouter), borrowerDefaultCollateral);
        pinjocRouter.placeOrder(
            usdc,
            weth,
            2000e6, // 90% of 1 WETH = 2500USDC
            borrowerDefaultCollateral,
            5e16, // 5% APY
            block.timestamp + 90 days,
            "MAY",
            2025,
            LendingOrderType.BORROW
        );
        vm.stopPrank();
    }
}

contract PinjocRouterLimitOrderTest is PinjocRouterBaseTest {

    function test_LendLimitOrder_Matched() public {
        setUp_BorrowLimitOrder();

        uint256 amount = 1000e6; // 100USDC
        uint256 rate = 5e16; // 5% APY
        uint256 maturity = block.timestamp + 90 days;
        string memory maturityMonth = "MAY";
        uint256 maturityYear = 2025;
        LendingOrderType lendingOrderType = LendingOrderType.LEND;

        vm.startPrank(lender);
        IERC20(usdc).approve(address(pinjocRouter), amount);
        pinjocRouter.placeOrder(
            usdc,
            weth,
            amount,
            0,
            rate,
            maturity,
            maturityMonth,
            maturityYear,
            lendingOrderType
        );
        vm.stopPrank();

        MockGTXOrderBook orderBook = MockGTXOrderBook(pinjocRouter.getOrderBookAddress(usdc, weth, "MAY", 2025));
        (uint256 id, address trader, uint256 amountOrderQueue, uint256 collateralAmountOrderQueue, , , ) = orderBook.orderBook(5e16, Side.SELL, 0);

        assertEq(IERC20(lendingPool.pinjocToken()).balanceOf(lender), amount);
        assertEq(IERC20(usdc).balanceOf(lender), lenderDefaultBalance - amount);

        assertEq(IERC20(usdc).balanceOf(borrower), amount);
        assertEq(IERC20(weth).balanceOf(address(lendingPool)), borrowerDefaultCollateral);

        assertEq(amountOrderQueue, borrowerDefaultBalance - amount);
        // assertEq(collateralAmountOrderQueue, 0);
    }

    function test_BorrowLimitOrder_Matched() public {
        setUp_LendLimitOrder();

        uint256 amount = 500e6; // 100USDC
        uint256 rate = 5e16; // 5% APY
        uint256 maturity = block.timestamp + 90 days;
        string memory maturityMonth = "MAY";
        uint256 maturityYear = 2025;
        LendingOrderType lendingOrderType = LendingOrderType.BORROW;

        vm.startPrank(borrower);
        IERC20(weth).approve(address(pinjocRouter), borrowerDefaultCollateral);
        pinjocRouter.placeOrder(
            usdc,
            weth,
            amount,
            borrowerDefaultCollateral,
            rate,
            maturity,
            maturityMonth,
            maturityYear,
            lendingOrderType
        );
        vm.stopPrank();

        MockGTXOrderBook orderBook = MockGTXOrderBook(pinjocRouter.getOrderBookAddress(usdc, weth, "MAY", 2025));
        (uint256 id, address trader, uint256 amountOrderQueue, uint256 collateralAmountOrderQueue, , , ) = orderBook.orderBook(5e16, Side.BUY, 0);
        console.log("order queue", id, " ", trader);

        assertEq(IERC20(lendingPool.pinjocToken()).balanceOf(lender), amount);
        assertEq(IERC20(usdc).balanceOf(lender), 0);

        assertEq(IERC20(usdc).balanceOf(borrower), amount);
        assertEq(IERC20(weth).balanceOf(address(lendingPool)), borrowerDefaultCollateral);

        assertEq(amountOrderQueue, lenderDefaultBalance - amount);
        // assertEq(collateralAmountOrderQueue, 0);
    }
}