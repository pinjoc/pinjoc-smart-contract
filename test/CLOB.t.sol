// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

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


contract CLOBTest is Test {
    IGTXRouter public router;

    function setUp() public {
        vm.createSelectFork("https://testnet.riselabs.xyz", 1);
        router = IGTXRouter(address(0xed2582315b355ad0FFdF4928Ca353773c9a588e3));
    }

    function test_CLOB() public {
        PoolKey memory key = PoolKey(address(0x7FB2a815Fa88c2096960999EC8371BccDF147874), address(0x02950119C4CCD1993f7938A55B8Ab8384C3CcE4F));
        Price price = Price.wrap(100);
        Quantity quantity = Quantity.wrap(100);
        Side side = Side.BUY;
        router.placeOrder(key, price, quantity, side);
    }
    
}