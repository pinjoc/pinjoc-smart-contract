// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey, PoolId, Currency, Price} from "../types/types.sol";
import {IOrderBook} from "./IOrderBook.sol";

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

    function createPool(
        PoolKey calldata key,
        uint256 _lotSize,
        uint256 _maxOrderAmount
    ) external;
}
