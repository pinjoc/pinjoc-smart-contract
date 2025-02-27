// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILendingPool {
    function ltv() external view returns (uint256);
    function oracle() external view returns (address);
    function supply(address user, uint256 amount) external;
    function supplyCollateral(address user, uint256 amount) external;
    function borrow(address user, uint256 amount) external;
}