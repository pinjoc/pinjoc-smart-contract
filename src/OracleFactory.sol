// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DynamicOracle} from "./Oracle.sol";

contract DynamicOracleFactory {
    // Error
    error ZeroAddress();

    function createOracle(address _baseFeed, address _quoteFeed) external returns (address) {
        // Input validation
        if (_baseFeed == address(0) || _quoteFeed == address(0)) revert ZeroAddress();
        
        // Create new oracle
        DynamicOracle oracle = new DynamicOracle(_baseFeed, _quoteFeed);
        
        return address(oracle);
    }
}