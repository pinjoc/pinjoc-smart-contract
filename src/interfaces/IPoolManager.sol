// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IOrderBook} from "./IOrderBook.sol";

struct PoolKey {
    address baseCurrency;
    address quoteCurrency;
}

type PoolId is bytes32;

interface IPoolManager {
    struct Pool {
        uint256 maxOrderAmount;
        uint256 lotSize;
        address baseCurrency;
        address quoteCurrency;
        IOrderBook orderBook;
    }

    function getPool(PoolKey calldata key) external view returns (Pool memory);
    function getPoolId(PoolKey calldata key) external pure returns (PoolId);
}
