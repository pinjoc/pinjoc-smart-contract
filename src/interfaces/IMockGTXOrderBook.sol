// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Status, Side} from "../types/Types.sol";

interface IMockGTXOrderBook {
    struct Order {
        uint256 id;
        address trader;
        uint256 amount;
        uint256 collateralAmount;
        uint256 price;
        Side side;
        Status status;
    }

    error OrderNotFound();

    event OrderMatched(uint256 orderId, uint256 matchedOrderId, Status statusOrder, Status statusMatchedOrder);
    event OrderRemovedFromBook(uint256 orderId, uint256 price, Side side);
    event Deposit(address indexed trader, uint256 amount, Side side);
    event Transfer(address indexed from, address indexed to, uint256 amount, Side side);

    event LimitOrderMatched(uint256 orderId, Status status);

    event LimitOrderCancelled(uint256 orderId, Status status);

    function placeLimitOrder(
        address trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 price,
        Side side
    ) external returns (uint256, address, address, uint256, uint256, uint256, Status);

    function getUserOrders(
        address trader
    ) external view returns (Order[] memory);

    function cancelOrder(address trader, uint256 orderId) external;

    function transferFrom(address from, address to, uint256 amount, Side side) external;
}
