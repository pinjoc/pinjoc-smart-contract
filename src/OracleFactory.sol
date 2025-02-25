// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Oracle} from "./Oracle.sol";

contract OracleFactory {
    // Error
    error ZeroAddress();

    function createOracle(address _baseFeed, address _quoteFeed) external returns (address) {
        // Input validation
        if (_baseFeed == address(0) || _quoteFeed == address(0)) revert ZeroAddress();
        
        // Create new oracle
        Oracle oracle = new Oracle(_baseFeed, _quoteFeed);
        
        return address(oracle);
    }
}