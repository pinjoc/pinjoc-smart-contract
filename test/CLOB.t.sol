// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGTXRouter} from "../src/interfaces/IGTXRouter.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IBalanceManager} from "../src/interfaces/IBalanceManager.sol";
import {PoolKey, Price, Quantity, Side, OrderId, Currency} from "../src/types/types.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockWETH} from "../src/mocks/MockWETH.sol";

contract CLOBTest is Test {
    IGTXRouter public router;
    IPoolManager private poolManager;
    IBalanceManager private balanceManager;
    Currency private weth;
    Currency private usdc;
    MockUSDC private mockUSDC;
    MockWETH private mockWETH;

    address private user = makeAddr("user");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    uint256 private initialBalanceUSDC = 100_000_000_000;
    uint256 private initialBalanceWETH = 10 ether;

    function setUp() public {
        vm.createSelectFork("https://testnet.riselabs.xyz");
        router = IGTXRouter(
            address(0xed2582315b355ad0FFdF4928Ca353773c9a588e3)
        );

        balanceManager = IBalanceManager(
            address(0x9B4fD469B6236c27190749bFE3227b85c25462D7)
        );

        poolManager = IPoolManager(
            address(0x35234957aC7ba5d61257d72443F8F5f0C431fD00)
        );

        mockUSDC = new MockUSDC();
        mockWETH = new MockWETH();

        mockUSDC.mint(user, initialBalanceUSDC);
        mockWETH.mint(user, initialBalanceWETH);
        usdc = Currency.wrap(address(mockUSDC));
        weth = Currency.wrap(address(mockWETH));

        PoolKey memory key = PoolKey(
            address(Currency.unwrap(weth)),
            address(Currency.unwrap(usdc))
        );
        uint256 lotSize = 1 ether;
        uint256 maxOrderAmount = 100 ether;
        poolManager.createPool(key, lotSize, maxOrderAmount);
    }

    function test_CLOB() public {
        uint256 depositAmount = 4 ether;
        vm.startPrank(user);
        IERC20(Currency.unwrap(weth)).approve(
            address(balanceManager),
            depositAmount
        );
        balanceManager.deposit(weth, depositAmount);

        PoolKey memory key = PoolKey(
            address(Currency.unwrap(weth)),
            address(Currency.unwrap(usdc))
        );

        IPoolManager.Pool memory pool = poolManager.getPool(key);
        Price price = Price.wrap(100);
        Quantity quantity = Quantity.wrap(100);
        Side side = Side.BUY;
        OrderId orderId = router.placeOrder(key, price, quantity, side);
        (uint48 orderCount, uint256 totalVolume) = router.getOrderQueue(
            key,
            side,
            price
        );

        console.log("Order Count:", orderCount);
        console.log("Total Volume:", totalVolume);
        assertEq(orderCount, 1);
        assertEq(totalVolume, Quantity.unwrap(quantity));

        // Check the balance and locked balance from the balance manager
        uint256 balance = balanceManager.getBalance(user, weth);
        uint256 lockedBalance = balanceManager.getLockedBalance(
            user,
            address(pool.orderBook),
            weth
        );

        console.log("User Balance:", balance);
        console.log("User Locked Balance:", lockedBalance);
        console.log("Order placed with ID:", OrderId.unwrap(orderId));
    }

    function testPlaceMarketOrderWithDeposit() public {
        PoolKey memory key = PoolKey(
            address(Currency.unwrap(weth)),
            address(Currency.unwrap(usdc))
        );
        Price price = Price.wrap(3000 * 10 ** 8);
        Price price2 = Price.wrap(3500 * 10 ** 8);
        Quantity quantity = Quantity.wrap(1 * 10 ** 18);
        // Quantity quantity2 = Quantity.wrap(1 * 10 ** 16);

        vm.startPrank(alice);
        mockWETH.mint(alice, initialBalanceWETH);
        IERC20(Currency.unwrap(weth)).approve(
            address(balanceManager),
            initialBalanceWETH
        );
        // balanceManager.deposit(weth, initialBalanceWETH);
        router.placeOrderWithDeposit(
            key,
            price,
            Quantity.wrap(Quantity.unwrap(quantity) / 2),
            Side.SELL
        );
        vm.stopPrank();

        vm.startPrank(bob);
        mockWETH.mint(bob, initialBalanceWETH);
        IERC20(Currency.unwrap(weth)).approve(
            address(balanceManager),
            initialBalanceWETH
        );
        // balanceManager.deposit(weth, initialBalanceWETH);
        router.placeOrderWithDeposit(
            key,
            price2,
            Quantity.wrap(2 * Quantity.unwrap(quantity)),
            Side.SELL
        );
        vm.stopPrank();

        vm.startPrank(user);
        mockWETH.mint(user, initialBalanceUSDC);
        IERC20(Currency.unwrap(usdc)).approve(
            address(balanceManager),
            initialBalanceUSDC
        );
        // balanceManager.deposit(usdc, initialBalanceUSDC);
        OrderId orderId = router.placeMarketOrderWithDeposit(
            key,
            price,
            Quantity.wrap(Quantity.unwrap(quantity) / 2),
            Side.BUY
        );

        (uint48 orderCount, uint256 totalVolume) = router.getOrderQueue(
            key,
            Side.SELL,
            price
        );
        console.log("Order Count:", orderCount);
        console.log("Total Volume:", totalVolume);
        console.log("Market order placed with ID:", OrderId.unwrap(orderId));

        assertEq(orderCount, 0);
        assertEq(totalVolume, 0);

        uint256 balance = balanceManager.getBalance(user, usdc);
        uint256 lockedBalance = balanceManager.getLockedBalance(
            user,
            address(poolManager.getPool(key).orderBook),
            usdc
        );

        console.log("User Balance:", balance);
        console.log("User Locked Balance:", lockedBalance);
        vm.stopPrank();
    }

    function testCancelOrder() public {
        PoolKey memory key = PoolKey(
            address(Currency.unwrap(weth)),
            address(Currency.unwrap(usdc))
        );
        Price price = Price.wrap(3000 * 10 ** 8);
        Quantity quantity = Quantity.wrap(10 * 10 ** 18);
        uint256 amount = 3000 * 10 * 10 ** 6;
        Side side = Side.BUY;

        // Place an order first
        vm.startPrank(user);
        IERC20(Currency.unwrap(usdc)).approve(address(balanceManager), amount);
        balanceManager.deposit(usdc, amount);
        OrderId orderId = router.placeOrder(key, price, quantity, side);
        router.cancelOrder(key, side, price, orderId);
        vm.stopPrank();

        (uint48 orderCount, uint256 totalVolume) = router.getOrderQueue(
            key,
            side,
            price
        );
        console.log("Order Count:", orderCount);
        console.log("Total Volume:", totalVolume);

        assertEq(orderCount, 0);
        assertEq(totalVolume, 0);

        // Check the balance and locked balance from the balance manager
        uint256 balance = balanceManager.getBalance(user, weth);
        uint256 lockedBalance = balanceManager.getLockedBalance(
            user,
            address(poolManager.getPool(key).orderBook),
            weth
        );

        console.log("User Balance:", balance);
        console.log("User Locked Balance:", lockedBalance);
        vm.stopPrank();
    }
}
