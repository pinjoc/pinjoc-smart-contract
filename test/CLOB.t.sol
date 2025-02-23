// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/mocks/MockUSDC.sol";
import "../src/mocks/MockWETH.sol";
struct PoolKey {
    address baseCurrency;
    address quoteCurrency;
}
type Price is uint64;
type Quantity is uint128;
enum Side {
    BUY,
    SELL
}
type OrderId is uint48;
type Currency is address;
enum Status {
    OPEN,
    PARTIALLY_FILLED,
    FILLED,
    CANCELLED,
    EXPIRED
}
type PoolId is bytes32;

interface IGTXRouter {
    function placeOrder(
        PoolKey calldata key,
        Price price,
        Quantity quantity,
        Side side
    ) external returns (OrderId orderId);

    function placeOrderWithDeposit(
        PoolKey calldata key,
        Price price,
        Quantity quantity,
        Side side
    ) external returns (OrderId orderId);

    function placeMarketOrder(
        PoolKey calldata key,
        Quantity quantity,
        Side side
    ) external returns (OrderId orderId);

    function placeMarketOrderWithDeposit(
        PoolKey calldata key,
        Price price,
        Quantity quantity,
        Side side
    ) external returns (OrderId orderId);

    function cancelOrder(PoolKey calldata key, Side side, Price price, OrderId orderId) external;
}

interface IOrderBook {
    struct Order {
        OrderId id;
        address user;
        OrderId next;
        OrderId prev;
        uint48 timestamp;
        uint48 expiry;
        Price price;
        Status status;
        Quantity quantity;
        Quantity filled;
    }

    struct PriceVolume {
        Price price;
        uint256 volume;
    }

    event OrderPlaced(
        OrderId indexed orderId,
        address indexed user,
        Side indexed side,
        Price price,
        Quantity quantity,
        uint48 timestamp,
        uint48 expiry,
        bool isMarketOrder,
        Status status
    );

    event OrderCancelled(
        OrderId indexed orderId, address indexed user, uint48 timestamp, Status status
    );

    function setRouter(address router) external;

    function placeOrder(
        Price price,
        Quantity quantity,
        Side side,
        address user
    ) external returns (OrderId);

    function placeMarketOrder(
        Quantity quantity,
        Side side,
        address user
    ) external returns (OrderId);

    function cancelOrder(Side side, Price price, OrderId orderId, address user) external;

    function getOrderQueue(
        Side side,
        Price price
    ) external view returns (uint48 orderCount, uint256 totalVolume);

    function getUserActiveOrders(address user) external view returns (Order[] memory);

    function getBestPrice(Side side) external view returns (PriceVolume memory);

    function getNextBestPrices(
        Side side,
        Price price,
        uint8 count
    ) external view returns (PriceVolume[] memory);
}

interface IPoolManager {
    error InvalidRouter();

    struct Pool {
        uint256 maxOrderAmount;
        uint256 lotSize;
        Currency baseCurrency;
        Currency quoteCurrency;
        IOrderBook orderBook;
    }

    event PoolCreated(
        PoolId indexed id,
        address indexed orderBook,
        Currency baseCurrency,
        Currency quoteCurrency,
        uint256 lotSize,
        uint256 maxOrderAmount
    );

    function setRouter(address router) external;

    function getPool(PoolKey calldata key) external view returns (Pool memory);

    function getPoolId(PoolKey calldata key) external pure returns (PoolId);

    function createPool(PoolKey calldata key, uint256 _lotSize, uint256 _maxOrderAmount) external;
}


contract CLOBTest is Test {
    IGTXRouter public router;
    IPoolManager public poolManager;
    IOrderBook public orderBook;
    
    address private user = makeAddr("user");

    MockUSDC private mockUSDC;
    MockWETH private mockWETH;
    Currency private weth;
    Currency private usdc;

    uint256 private initialBalance = 1000 ether;
    uint256 private initialBalanceUSDC = 100_000_000_000;
    uint256 private initialBalanceWETH = 10 ether;

    function setUp() public {
        vm.createSelectFork("https://testnet.riselabs.xyz");
        router = IGTXRouter(address(0xed2582315b355ad0FFdF4928Ca353773c9a588e3));
        poolManager = IPoolManager(address(0x35234957aC7ba5d61257d72443F8F5f0C431fD00));
        mockUSDC = new MockUSDC();
        mockWETH = new MockWETH();

        mockUSDC.mint(user, initialBalanceUSDC);
        mockWETH.mint(user, initialBalanceWETH);
        usdc = Currency.wrap(address(mockUSDC));
        weth = Currency.wrap(address(mockWETH));
    }

    function test_CLOB() public {
        PoolKey memory key = PoolKey(address(Currency.unwrap(weth)), address(Currency.unwrap(usdc)));
        uint256 lotSize = 1 ether;
        uint256 maxOrderAmount = 100 ether;
        poolManager.createPool(key, lotSize, maxOrderAmount);
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
