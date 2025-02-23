// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PoolKey, Price, Quantity, Side, OrderId} from "../types/types.sol";

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

    function cancelOrder(
        PoolKey calldata key,
        Side side,
        Price price,
        OrderId orderId
    ) external;

    function getOrderQueue(
        PoolKey calldata key,
        Side side,
        Price price
    ) external view returns (uint48 orderCount, uint256 totalVolume);
}
