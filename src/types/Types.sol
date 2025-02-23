// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

enum Status {
    OPEN,
    PARTIALLY_FILLED,
    FILLED,
    CANCELLED,
    EXPIRED
}

enum Side {
    BUY,
    SELL
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
    function convertToSide(LendingOrderType lendingOrderType) internal pure returns (Side) {
        return lendingOrderType == LendingOrderType.LEND ? Side.BUY : Side.SELL;
    }
}

library TokenOrderTypeLibrary {
    function opposite(TokenOrderType tokenOrderType) internal pure returns (TokenOrderType) {
        return tokenOrderType == TokenOrderType.BUY ? TokenOrderType.SELL : TokenOrderType.BUY;
    }
    function convertToSide(TokenOrderType tokenOrderType) internal pure returns (Side) {
        return tokenOrderType == TokenOrderType.BUY ? Side.BUY : Side.SELL;
    }
}

library Uint256Library {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


using LendingOrderTypeLibrary for LendingOrderType global;
using TokenOrderTypeLibrary for TokenOrderType global;