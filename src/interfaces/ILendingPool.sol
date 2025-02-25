// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILendingPool {
    function supply(address user, uint256 amount) external;
    function borrow(address user, uint256 amount) external;
}