// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Status, Side} from "../types/Types.sol";

interface IMockGTXOBLending {

    /// @dev Order data
    struct Order {
        uint256 id;
        address trader;
        uint256 amount;           // If BUY => how many quoteTokens. If SELL => how many baseTokens
        uint256 collateralAmount; // For SELL side (borrowers)
        uint256 price;            // e.g. interest rate or other price logic
        Side side;                // BUY = LEND, SELL = BORROW
        Status status;            // OPEN, FILLED, PARTIALLY_FILLED, CANCELLED
    }

    /**
     * @dev Struct to capture matched info for distribution
     * @param orderId   The matched order's ID
     * @param trader    Trader who owns this matched order
     * @param amount    The matched order's final (remaining) "amount" after matching
     * @param collateralAmount The matched order's final (remaining) collateral if SELL side
     * @param side      The matched order side (BUY or SELL)
     * @param percentMatch Matched fraction in 1e18 scale
     * @param status    The final status (FILLED or PARTIALLY_FILLED)
     */
    struct MatchedInfo {
        uint256 orderId;
        address trader;
        uint256 amount;
        uint256 collateralAmount;
        Side side;
        uint256 percentMatch; // e.g. (matchedAmt * 1e18) / originalOrderAmount
        Status status;
    }

    // -------------------------------------------------------------------
    //                              EVENTS
    // -------------------------------------------------------------------
    event OrderPlaced(
        uint256 orderId,
        address indexed trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 price,
        Side side,
        Status status
    );
    event Deposit(address indexed trader, uint256 amount, Side side);
    event OrderMatched(
        uint256 newOrderId,
        uint256 matchedOrderId,
        Status newOrderStatus,
        Status matchedOrderStatus
    );
    event OrderRemovedFromQueue(uint256 orderId, uint256 price, Side side);
    event Transfer(address indexed from, address indexed to, uint256 amount, Side side);
    event LimitOrderCancelled(uint256 orderId, Status status);

    function placeOrder(
        address trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 price,
        Side side
    ) external returns (MatchedInfo[] memory matchedBuyOrders, MatchedInfo[] memory matchedSellOrders);

    function cancelOrder(address trader, uint256 orderId) external;

    function transferFrom(address from, address to, uint256 amount, Side side) external;

    function getUserOrders(address trader) external view returns (Order[] memory);
}
