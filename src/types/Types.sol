// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

enum Status {
    OPEN,
    PARTIALLY_FILLED,
    FILLED,
    CANCELLED,
    EXPIRED
}

/// @notice Enum representing the side of an lending order
enum LendingOrderType {
    LEND,
    BORROW
}

/// @notice Enum representing the side of an token order
enum TokenOrderType {
    BUY,
    SELL
}

library LendingOrderTypeLibrary {
    function opposite(LendingOrderType lendingOrderType) internal pure returns (LendingOrderType) {
        return lendingOrderType == LendingOrderType.LEND ? LendingOrderType.BORROW : LendingOrderType.LEND;
    }
}

library TokenOrderTypeLibrary {
    function opposite(TokenOrderType tokenOrderType) internal pure returns (TokenOrderType) {
        return tokenOrderType == TokenOrderType.BUY ? TokenOrderType.SELL : TokenOrderType.BUY;
    }
}


using LendingOrderTypeLibrary for LendingOrderType global;
using TokenOrderTypeLibrary for TokenOrderType global;