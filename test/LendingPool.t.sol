// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LendingPoolManager} from "../src/LendingPoolManager.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {PinjocToken} from "../src/PinjocToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";

contract LendingPoolBaseTest is Test {

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    MockOracle wethUsdcOracle;
    LendingPoolManager public lendingPoolManager;
    LendingPool public lendingPool;

    address owner = makeAddr("owner");

    address lender = makeAddr("lender");
    uint256 lenderDefaultBalance = 1000e6; // 1000USDC

    address borrower = makeAddr("borrower");
    uint256 borrowerDefaultBalance = 1e18; // 1WETH = 2500USDC

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/Ea4M-V84UObD22z2nNlwDD9qP8eqZuSI");
        
        wethUsdcOracle = new MockOracle(weth, usdc);
        wethUsdcOracle.setPrice(2500e6); // 1 WETH = 2500USDC

        lendingPoolManager = new LendingPoolManager();
        lendingPoolManager.setLtv(90e16); // SET LOAN TO VALUE TO 90%
        lendingPool = LendingPool(
            lendingPoolManager.createLendingPool(
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
        deal(weth, borrower, borrowerDefaultBalance); // 1 WETH = 2500USDC
    }

    function setUp_DebtSupply() public {
        vm.startPrank(lender);
        IERC20(usdc).approve(address(lendingPool), lenderDefaultBalance);
        lendingPool.supply(lender, lenderDefaultBalance);
        vm.stopPrank();
    }

    function setUp_CollateralSupply() public {
        vm.startPrank(borrower);
        IERC20(weth).approve(address(lendingPool), borrowerDefaultBalance);
        lendingPool.supplyCollateral(borrowerDefaultBalance);
        vm.stopPrank();
    }

    function setUp_Borrow() public {
        vm.startPrank(borrower);
        lendingPool.borrow(borrower, 1000e6);
        vm.stopPrank();
    }
}

contract LendingPoolScenarioTest is LendingPoolBaseTest {
    
    function test_Scenario_AccrueInterest() public {
        setUp_DebtSupply();
        setUp_CollateralSupply();
        setUp_Borrow();

        console.log('total borrow assets before',lendingPool.totalBorrowAssets());
        console.log('total supply assets before',lendingPool.totalSupplyAssets());
        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest();

        assertEq(lendingPool.totalBorrowAssets(), 1000e6 + 50e6);
        assertEq(lendingPool.totalSupplyAssets(), 1000e6 + 50e6);
    }
}

contract LendingPoolSupplyTest is LendingPoolBaseTest {
    
    function test_Supply() public {
        setUp_DebtSupply();

        assertEq(IERC20(usdc).balanceOf(lender), 0);
        assertEq(IERC20(lendingPool.pinjocToken()).balanceOf(lender), 1000e6);
    }

    function test_Supply_RevertIf_ZeroAmount() public {
        vm.startPrank(lender);
        vm.expectRevert(LendingPool.ZeroAmount.selector);
        lendingPool.supply(lender, 0);
        vm.stopPrank();
    }

    function test_Supply_RevertIf_InsufficientLiquidity() public {
        vm.startPrank(lender);
        vm.expectRevert(LendingPool.InsufficientLiquidity.selector);
        lendingPool.supply(lender, 1100e6);
        vm.stopPrank();
    }
}

contract LendingPoolBorrowTest is LendingPoolBaseTest {

    function test_Borrow() public {
        setUp_DebtSupply();
        setUp_CollateralSupply();
        setUp_Borrow();

        assertEq(IERC20(usdc).balanceOf(borrower), 1000e6);
    }

    function test_Borrow_RevertIf_ZeroAmount() public {
        setUp_DebtSupply();
        setUp_CollateralSupply();

        vm.startPrank(borrower);
        vm.expectRevert(LendingPool.ZeroAmount.selector);
        lendingPool.borrow(borrower, 0);
        vm.stopPrank();
    }

    function test_Borrow_RevertIf_InsufficientLiquidity() public {
        setUp_DebtSupply();
        setUp_CollateralSupply();

        vm.startPrank(borrower);
        vm.expectRevert(LendingPool.InsufficientLiquidity.selector);
        lendingPool.borrow(borrower, 1100e6); // contract should only have 1000e6
        vm.stopPrank();
    }
}

contract LendingPoolWithdrawTest is LendingPoolBaseTest {
    
    function test_Withdraw() public {
        // lender supply 1000 usdc
        setUp_DebtSupply();

        vm.startPrank(lender);
        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest();
        lendingPool.withdraw(1000e6);
        vm.stopPrank();
        
        assertEq(IERC20(usdc).balanceOf(lender), 1000e6);
    }

    function test_Withdraw_RevertIf_ZeroAmount() public {
        // lender supply 1000 usdc
        setUp_DebtSupply();

        vm.startPrank(lender);
        vm.expectRevert(LendingPool.ZeroAmount.selector);
        lendingPool.withdraw(0);
        vm.stopPrank();
    }

    function test_Withdraw_RevertIf_InsufficientShares() public {
        // lender supply 1000 usdc
        setUp_DebtSupply();

        vm.startPrank(lender);
        vm.expectRevert(LendingPool.InsufficientShares.selector);
        lendingPool.withdraw(2000e6);
        vm.stopPrank();
    }

    function test_Withdraw_RevertIf_InsufficientLiquidity() public {
        // lender supply 1000 usdc
        setUp_DebtSupply();
        
        // borrower borrow 500 usdc
        setUp_CollateralSupply();
        vm.startPrank(borrower);
        lendingPool.borrow(borrower, 500e6);
        vm.stopPrank();

        vm.startPrank(lender);
        vm.expectRevert(LendingPool.InsufficientLiquidity.selector);
        lendingPool.withdraw(1000e6);
        vm.stopPrank();
    }
}