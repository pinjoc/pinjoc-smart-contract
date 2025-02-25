// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILendingPool {
    function supply(uint256 amount) external;
    function borrow(uint256 amount) external;
}