// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IMockGTXOrderBook} from "../interfaces/IMockGTXOrderBook.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Status, Side} from "../types/Types.sol";

contract MockGTXOrderBook is IMockGTXOrderBook, Ownable {

    // buy = lend, thus must deposit debt token = quote token
    // sell = borrow, thus must deposit collateral token = base token

    IERC20 public quoteToken; // USDC
    IERC20 public baseToken; // ETH

    uint256 public orderCount;
    mapping(address => uint256) public baseBalances;
    mapping(address => uint256) public quoteBalances;

    mapping(address => Order[]) public traderOrders;
    mapping(uint256 => mapping(Side => Order[])) public orderBook;

    constructor(address _quoteToken, address _baseToken) Ownable(msg.sender) {
        quoteToken = IERC20(_quoteToken);
        baseToken = IERC20(_baseToken);
    }

    function placeLimitOrder(
        address trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 price,
        Side side
    ) external returns (uint256, address, address, uint256, uint256, uint256, Status) {
        uint256 orderId = orderCount;
        orderCount++;

        // Handle deposit inside placeLimitOrder
        if (side == Side.BUY) {
            require(quoteToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
            quoteBalances[trader] += amount;
            emit Deposit(trader, amount, Side.BUY);
        } else {
            require(baseToken.transferFrom(msg.sender, address(this), collateralAmount), "Transfer failed");
            baseBalances[trader] += collateralAmount;
            emit Deposit(trader, collateralAmount, Side.SELL);
        }

        Order memory newOrder = Order(orderId, trader, amount, collateralAmount, price, side, Status.OPEN);

        Side oppositeSide = side == Side.BUY ? Side.SELL : Side.BUY;
        Order[] storage oppositeOrders = orderBook[price][oppositeSide];

        address buyer;
        address seller;
        uint256 buyerAmount;
        uint256 sellerAmount;
        if (oppositeOrders.length > 0) {
            Order storage matchingOrder = oppositeOrders[0];

            if (matchingOrder.side == Side.BUY) {
                buyer = matchingOrder.trader;
                seller = newOrder.trader;
                buyerAmount = matchingOrder.amount;
                sellerAmount =  newOrder.amount;
                collateralAmount = newOrder.collateralAmount;
            } else {
                buyer = newOrder.trader;
                seller = matchingOrder.trader;
                buyerAmount = newOrder.amount;
                sellerAmount = matchingOrder.amount;
                collateralAmount = matchingOrder.collateralAmount;
            }

            if (matchingOrder.amount <= newOrder.amount) {
                matchingOrder.amount = 0;
                newOrder.amount -= matchingOrder.amount;

                if(newOrder.amount == 0) {
                    matchingOrder.status = Status.FILLED;
                    newOrder.status = Status.FILLED;
                    emit OrderMatched(newOrder.id, matchingOrder.id, Status.FILLED, Status.FILLED);
                } else {
                    matchingOrder.status = Status.FILLED;
                    newOrder.status = Status.PARTIALLY_FILLED;
                    emit OrderMatched(newOrder.id, matchingOrder.id, Status.PARTIALLY_FILLED, Status.FILLED);
                }
                
            } else {
                matchingOrder.amount -= newOrder.amount;
                matchingOrder.status = Status.PARTIALLY_FILLED;
                newOrder.status = Status.FILLED;
                emit OrderMatched(newOrder.id, matchingOrder.id, Status.FILLED, Status.PARTIALLY_FILLED);
            }
        }
        else {
            orderBook[price][side].push(newOrder);
            traderOrders[trader].push(newOrder);
        }

        return (orderId, buyer, seller, buyerAmount, sellerAmount, collateralAmount, newOrder.status);
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

                // Refund based on escrow balance (not checking real ERC20 balance)
                if (orders[i].side == Side.BUY) {
                    uint256 refundAmount = orders[i].amount;
                    require(quoteBalances[trader] >= refundAmount, "Insufficient escrow balance");
                    quoteBalances[trader] -= refundAmount;
                    require(quoteToken.transfer(trader, refundAmount), "Refund failed");
                } else {
                    uint256 collateralAmount = orders[i].collateralAmount;
                    require(baseBalances[trader] >= collateralAmount, "Insufficient escrow balance");
                    baseBalances[trader] -= collateralAmount;
                    require(baseToken.transfer(trader, collateralAmount), "Refund failed");
                }

                break;
            }
        }
    }

    function transferFrom(address from, address to, uint256 amount, Side side) external onlyOwner {
        if (side == Side.BUY) {
            require(quoteBalances[from] >= amount, "Insufficient quote escrow");
            quoteBalances[from] -= amount;
            require(quoteToken.transfer(to, amount), "Quote transfer failed");
        } else {
            require(baseBalances[from] >= amount, "Insufficient base escrow");
            baseBalances[from] -= amount;
            require(baseToken.transfer(to, amount), "Base transfer failed");
        }

        emit Transfer(from, to, amount, side);
    }
}