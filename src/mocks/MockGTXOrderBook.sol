// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMockGTXOrderBook} from "../interfaces/IMockGTXOrderBook.sol";
import {Status, Side} from "../types/Types.sol";

contract MockGTXOrderBook is IMockGTXOrderBook {

    uint256 public orderCount;

    // Mapping from trader address to their orders.
    mapping(address => Order[]) public traderOrders;

    // Public function to place a limit order with added baseToken and quoteToken parameters.
    function placeLimitOrder(
        address baseToken,
        address quoteToken,
        address trader,
        uint256 amount,
        uint256 price,
        Side side,
        bool isMatch
    ) external returns (uint256, Status) {
        uint256 orderId = orderCount;
        orderCount++;
        Order memory newOrder = Order(orderId, baseToken, quoteToken, trader, amount, price, side, Status.OPEN);
        emit LimitOrderPlaced(orderId, baseToken, quoteToken, trader, amount, price, side, Status.OPEN);

        if (isMatch) {
            newOrder.status = Status.FILLED;
            emit LimitOrderMatched(orderId, Status.FILLED);
        }

        traderOrders[trader].push(newOrder);

        return (orderId, newOrder.status);
    }

    function getUserOrders(address trader) external view returns (Order[] memory) {
        return traderOrders[trader];
    }

    function cancelOrder(address trader, uint256 orderId) external {
        Order[] storage orders = traderOrders[trader];

        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].id == orderId) {
                orders[i].status = Status.CANCELLED;
                emit LimitOrderCancelled(orderId, Status.CANCELLED);
                break;
            }
        }
    }
}