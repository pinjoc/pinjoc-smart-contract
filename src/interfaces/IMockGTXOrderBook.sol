// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Status, Side} from "../types/Types.sol";

interface IMockGTXOrderBook {

    struct Order {
        uint256 id;
        address baseToken;
        address quoteToken;
        address trader;
        uint256 amount;
        uint256 price;
        Side side;
        Status status;
    }

    event LimitOrderPlaced(
        uint256 orderId,
        address baseToken,
        address quoteToken,
        address trader,
        uint256 amount,
        uint256 price,
        Side side,
        Status status
    );

    event LimitOrderMatched(
        uint256 orderId,
        Status status
    );

    event LimitOrderCancelled(
        uint256 orderId,
        Status status
    );

    function placeLimitOrder(
        address baseToken,
        address quoteToken,
        address trader,
        uint256 amount,
        uint256 price,
        Side side,
        bool isMatch
    ) external returns (uint256, Status);
    function getActiveOrders(address trader) external view returns (Order[] memory);
    function cancelOrder(address trader, uint256 orderId) external;
}