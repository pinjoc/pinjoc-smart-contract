// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IMockGTXOBLending} from "../interfaces/IMockGTXOBLending.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Status, Side} from "../types/Types.sol";

/**
 * @title MockGTXOBLending
 * @notice Example order-book contract for lending/borrowing
 *         BUY = LEND (depositing quoteToken -> USDC)
 *         SELL = BORROW (depositing baseToken -> ETH)
 */
contract MockGTXOBLending is IMockGTXOBLending, Ownable {
    IERC20 public quoteToken; // USDC
    IERC20 public baseToken;  // WETH or ETH-wrapped

    /// @dev Number of orders ever created
    uint256 public orderCount;

    /// @dev Escrow balances
    mapping(address => uint256) public baseBalances;   // Collateral from SELLers
    mapping(address => uint256) public quoteBalances;  // Debt tokens from BUYers

    

    /// @dev Each trader can have multiple orders
    mapping(address => Order[]) public traderOrders;

    /// @dev Order queue by (price -> side -> array of orders)
    mapping(uint256 => mapping(Side => Order[])) public orderQueue;



    constructor(address _quoteToken, address _baseToken) Ownable(msg.sender) {
        quoteToken = IERC20(_quoteToken);
        baseToken  = IERC20(_baseToken);
    }

    /**
     * @notice Place a new order (Buy = Lend, Sell = Borrow) and match it with multiple opposite orders
     * @param trader The address placing the order (often msg.sender)
     * @param amount For BUY: how many quoteTokens. For SELL: how many baseTokens to borrow
     * @param collateralAmount For SELL: how many baseTokens are deposited
     * @param price The interest rate or another logic
     * @param side BUY = LEND, SELL = BORROW
     *
     * @return matchedBuyOrders Array of matched BUY orders (FILLED or PARTIALLY_FILLED)
     * @return matchedSellOrders Array of matched SELL orders (FILLED or PARTIALLY_FILLED)
     */
    function placeOrder(
        address trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 price,
        Side side
    ) external returns (MatchedInfo[] memory matchedBuyOrders, MatchedInfo[] memory matchedSellOrders) {
        // ---------------------------
        // 1. Transfer tokens to escrow
        // ---------------------------
        if (side == Side.BUY) {
            // LEND => deposit quoteToken
            require(
                quoteToken.transferFrom(msg.sender, address(this), amount),
                "quoteToken transfer failed"
            );
            quoteBalances[trader] += amount;
            emit Deposit(trader, amount, Side.BUY);
        } else {
            // BORROW => deposit baseToken
            require(
                baseToken.transferFrom(msg.sender, address(this), collateralAmount),
                "baseToken transfer failed"
            );
            baseBalances[trader] += collateralAmount;
            emit Deposit(trader, collateralAmount, Side.SELL);
        }

        // ---------------------------
        // 2. Build the new order
        // ---------------------------
        uint256 orderId = orderCount;
        orderCount++;

        Order memory newOrder = Order({
            id: orderId,
            trader: trader,
            amount: amount,
            collateralAmount: collateralAmount,
            price: price,
            side: side,
            status: Status.OPEN
        });

        emit OrderPlaced(orderId, trader, amount, collateralAmount, price, side, Status.OPEN);

        // Arrays to store matched results
        MatchedInfo[] memory tempBuyMatches  = new MatchedInfo[](50); // arbitrary max
        MatchedInfo[] memory tempSellMatches = new MatchedInfo[](50);
        uint256 buyMatchCount  = 0;
        uint256 sellMatchCount = 0;

        // Opposite side
        Side oppositeSide = (side == Side.BUY) ? Side.SELL : Side.BUY;
        Order[] storage oppQueue = orderQueue[price][oppositeSide];

        // Keep track of total matched for the newOrder
        uint256 totalMatchedForNewOrder;
        uint256 originalNewAmt = newOrder.amount;

        // ---------------------------
        // 3. Match loop
        // ---------------------------
        uint256 i = 0;
        while (i < oppQueue.length && newOrder.amount > 0) {
            Order storage matchOrder = oppQueue[i];

            // Skip if FILLED, CANCELLED, or same trader
            if (matchOrder.status == Status.FILLED || matchOrder.status == Status.CANCELLED || matchOrder.trader == trader) {
                i++;
                continue;
            }

            uint256 originalMatchAmt = matchOrder.amount;
            uint256 matchedAmt = 0;

            if (matchOrder.amount <= newOrder.amount) {
                // matchOrder fully filled
                matchedAmt        = matchOrder.amount;
                newOrder.amount  -= matchedAmt;
                matchOrder.amount = 0;
                matchOrder.status = Status.FILLED;

                if (newOrder.amount == 0) {
                    newOrder.status = Status.FILLED;
                } else {
                    newOrder.status = Status.PARTIALLY_FILLED;
                }

                emit OrderMatched(newOrder.id, matchOrder.id, newOrder.status, Status.FILLED);

                // Record how many tokens the newOrder matched
                totalMatchedForNewOrder += matchedAmt;

                // store matchOrder details
                _storeMatchInfo(matchOrder, matchedAmt, originalMatchAmt, tempBuyMatches, tempSellMatches, buyMatchCount, sellMatchCount);
                if (matchOrder.side == Side.BUY) {
                    buyMatchCount++;
                } else {
                    sellMatchCount++;
                }

                // Remove matchOrder from queue (swap+pop)
                _removeFromQueueByIndex(oppQueue, i, price, matchOrder.side);

            } else {
                // newOrder is fully filled, matchOrder partial
                matchedAmt         = newOrder.amount;
                matchOrder.amount -= matchedAmt;
                matchOrder.status  = Status.PARTIALLY_FILLED;
                newOrder.amount    = 0;
                newOrder.status    = Status.FILLED;

                emit OrderMatched(newOrder.id, matchOrder.id, Status.FILLED, Status.PARTIALLY_FILLED);

                totalMatchedForNewOrder += matchedAmt;

                // matchOrder
                _storeMatchInfo(matchOrder, matchedAmt, originalMatchAmt, tempBuyMatches, tempSellMatches, buyMatchCount, sellMatchCount);
                if (matchOrder.side == Side.BUY) {
                    buyMatchCount++;
                } else {
                    sellMatchCount++;
                }

                // newOrder is exhausted => break
                i++;
                break;
            }

            i++;
        }

        // ----------------------------------
        // 4. If newOrder is STILL OPEN
        // ----------------------------------
        if (newOrder.status == Status.OPEN) {
            // No fill happened; push entire order
            orderQueue[newOrder.price][newOrder.side].push(newOrder);
            traderOrders[newOrder.trader].push(newOrder);
        } else {
            // (FILLED or PARTIALLY_FILLED)
            // We record it once in traderOrders
            traderOrders[newOrder.trader].push(newOrder);
        }

        // ----------------------------------
        // 5. *Now* store newOrder's matched info if it partially or fully filled
        //    (Because newOrder is only one, we do this exactly once).
        // ----------------------------------
        if (totalMatchedForNewOrder > 0) {
            // We'll store newOrder's final leftover
            // partial fill leftover = newOrder.amount
            // final status is newOrder.status
            // matched fraction = totalMatchedForNewOrder / originalNewAmt

            uint256 denom = (originalNewAmt == 0) ? 1 : originalNewAmt;
            uint256 pMatch = (totalMatchedForNewOrder * 1e18) / denom;

            MatchedInfo memory newOrderInfo = MatchedInfo({
                orderId: newOrder.id,
                trader: newOrder.trader,
                amount: originalNewAmt,
                collateralAmount: newOrder.collateralAmount,
                side: newOrder.side,
                percentMatch: pMatch,
                status: newOrder.status
            });

            // If newOrder is BUY, add to buy array; else to sell array
            if (newOrder.side == Side.BUY) {
                tempBuyMatches[buyMatchCount] = newOrderInfo;
                buyMatchCount++;
            } else {
                tempSellMatches[sellMatchCount] = newOrderInfo;
                sellMatchCount++;
            }
        }

        // ----------------------------------
        // 6. Build final matched arrays
        // ----------------------------------
        matchedBuyOrders  = new MatchedInfo[](buyMatchCount);
        matchedSellOrders = new MatchedInfo[](sellMatchCount);

        uint256 buyIdx  = 0;
        uint256 sellIdx = 0;

        // copy buy matches
        for (uint256 j = 0; j < 50; j++) {
            MatchedInfo memory infoB = tempBuyMatches[j];
            if (infoB.trader != address(0)) {
                matchedBuyOrders[buyIdx] = infoB;
                buyIdx++;
                if (buyIdx == buyMatchCount) break;
            }
        }

        // copy sell matches
        for (uint256 k = 0; k < 50; k++) {
            MatchedInfo memory infoS = tempSellMatches[k];
            if (infoS.trader != address(0)) {
                matchedSellOrders[sellIdx] = infoS;
                sellIdx++;
                if (sellIdx == sellMatchCount) break;
            }
        }

        // Return both arrays
        return (matchedBuyOrders, matchedSellOrders);
    }

    /**
     * @notice Cancel an existing order. Removes it from the queue and refunds escrow.
     * @param trader The owner of the order
     * @param orderId The ID of the order to cancel
     */
    function cancelOrder(address trader, uint256 orderId) external {
        Order[] storage orders = traderOrders[trader];
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].id == orderId && orders[i].status == Status.OPEN) {
                Order storage orderFound = orders[i];
                orderFound.status = Status.CANCELLED;
                emit LimitOrderCancelled(orderId, Status.CANCELLED);

                // Remove from queue if present
                uint256 idx = _findOrderIndex(
                    orderQueue[orderFound.price][orderFound.side],
                    orderId
                );
                if (idx < orderQueue[orderFound.price][orderFound.side].length) {
                    _removeFromQueueByIndex(
                        orderQueue[orderFound.price][orderFound.side],
                        idx,
                        orderFound.price,
                        orderFound.side
                    );
                }

                // Refund escrow
                if (orderFound.side == Side.BUY) {
                    uint256 refundAmt = orderFound.amount;
                    require(quoteBalances[trader] >= refundAmt, "Insufficient quote escrow");
                    quoteBalances[trader] -= refundAmt;
                    require(quoteToken.transfer(trader, refundAmt), "Refund failed");
                } else {
                    uint256 refundCollat = orderFound.collateralAmount;
                    require(baseBalances[trader] >= refundCollat, "Insufficient base escrow");
                    baseBalances[trader] -= refundCollat;
                    require(baseToken.transfer(trader, refundCollat), "Refund failed");
                }
                break;
            }
        }
    }

    /**
     * @notice Transfer escrow from one user to another. 
     *         Typically used by the contract owner to move matched tokens around.
     */
    function transferFrom(address from, address to, uint256 amount, Side side) external onlyOwner {
        if (side == Side.BUY) {
            require(quoteBalances[from] >= amount, "Not enough quote escrow");
            quoteBalances[from] -= amount;
            require(quoteToken.transfer(to, amount), "Transfer failed");
        } else {
            require(baseBalances[from] >= amount, "Not enough base escrow");
            baseBalances[from] -= amount;
            require(baseToken.transfer(to, amount), "Transfer failed");
        }
        emit Transfer(from, to, amount, side);
    }

    // -------------------------------------------------------
    //                   VIEW FUNCTIONS
    // -------------------------------------------------------
    function getUserOrders(address trader) external view returns (Order[] memory) {
        return traderOrders[trader];
    }

    // -------------------------------------------------------
    //               INTERNAL HELPER METHODS
    // -------------------------------------------------------
    /**
     * @dev Store info about a matchOrder that got partially/fully filled
     * @param matchOrder The existing order in the queue
     * @param matchedAmt How many tokens matched
     * @param originalMatchAmt The original amount of that matchOrder before matching
     */
    function _storeMatchInfo(
        Order storage matchOrder,
        uint256 matchedAmt,
        uint256 originalMatchAmt,
        MatchedInfo[] memory buyArr,
        MatchedInfo[] memory sellArr,
        uint256 buyCount,
        uint256 sellCount
    ) internal view {
        // matchedAmt / originalMatchAmt
        uint256 denom = (originalMatchAmt == 0) ? 1 : originalMatchAmt;
        uint256 pMatch = (matchedAmt * 1e18) / denom;

        MatchedInfo memory info = MatchedInfo({
            orderId: matchOrder.id,
            trader: matchOrder.trader,
            amount: originalMatchAmt,  // original matched
            collateralAmount: matchOrder.collateralAmount,
            side: matchOrder.side,
            percentMatch: pMatch,
            status: matchOrder.status
        });

        if (matchOrder.side == Side.BUY) {
            buyArr[buyCount] = info;
        } else {
            sellArr[sellCount] = info;
        }
    }

    /**
     * @dev Remove an order from the queue by index (swap and pop).
     */
    function _removeFromQueueByIndex(
        Order[] storage queue,
        uint256 index,
        uint256 price,
        Side side
    ) internal {
        uint256 length = queue.length;
        if (length > 0 && index < length) {
            uint256 rmOrderId = queue[index].id;
            queue[index] = queue[length - 1];
            queue.pop();

            emit OrderRemovedFromQueue(rmOrderId, price, side);
        }
    }

    /**
     * @dev Finds an order's index by ID (only for Status.OPEN).
     *      Returns a large number if not found.
     */
    function _findOrderIndex(Order[] storage orders, uint256 orderId) internal view returns (uint256) {
        for (uint256 i = 0; i < orders.length; i++) {
            // Only remove if status == OPEN
            if (orders[i].id == orderId && orders[i].status == Status.OPEN) {
                return i;
            }
        }
        return type(uint256).max;
    }
}
