// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
    
}