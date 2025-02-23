// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

type OrderId is uint48;
type Quantity is uint128;
type PoolId is bytes32;

enum Side {
    BUY,
    SELL
}

enum Status {
    OPEN,
    PARTIALLY_FILLED,
    FILLED,
    CANCELLED,
    EXPIRED
}

struct PoolKey {
    address baseCurrency;
    address quoteCurrency;
}
