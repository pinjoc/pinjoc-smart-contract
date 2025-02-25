// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILendingPoolManager {

    error Unauthorized(address user);
    error LendingPoolAlreadyExist();
    error InvalidCreateLendingParameter();

    event LendingPoolCreated(
        address lendingPool,
        address debtToken,
        address collateralToken,
        uint256 rate,
        uint256 maturity,
        string maturityMonth,
        uint256 maturityYear,
        address oracle
    );

    function getLendingPool(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string calldata _maturityMonth,
        uint256 _maturityYear
    ) external view returns (address);
}