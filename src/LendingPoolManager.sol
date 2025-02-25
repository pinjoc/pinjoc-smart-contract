// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ILendingPoolManager} from "./interfaces/ILendingPoolManager.sol";
import {LendingPool} from "./LendingPool.sol";
import {Uint256Library} from "./types/Types.sol";

using Uint256Library for uint256;

contract LendingPoolManager is Ownable, ReentrancyGuard, ILendingPoolManager {

    uint256 public ltv;
    mapping(string => address) public lendingPools;

    constructor() Ownable(msg.sender) {}

    function setLtv(uint256 _ltv) external onlyOwner {
        ltv = _ltv;
    }

    function _generateKey(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string calldata _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                IERC20Metadata(_debtToken).symbol(),
                IERC20Metadata(_collateralToken).symbol(),
                _rate.toString(),
                _maturityMonth,
                _maturityYear.toString()
            )
        );
    }

    function createLendingPool(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        uint256 _maturity,
        string calldata _maturityMonth,
        uint256 _maturityYear,
        address _oracle
    ) public onlyOwner returns (address) {
        if (
            _debtToken == address(0) ||
            _collateralToken == address(0) ||
            _rate == 0 ||
            _maturity == 0
        ) revert InvalidCreateLendingParameter();
        string memory key = _generateKey(_debtToken, _collateralToken, _rate, _maturityMonth, _maturityYear);
        if (lendingPools[key] != address(0)) revert LendingPoolAlreadyExist();

        lendingPools[key] = address(
            new LendingPool(
                _debtToken,
                _collateralToken,
                _oracle,
                _rate,
                ltv,
                _maturity,
                _maturityMonth,
                _maturityYear
            )
        );

        emit LendingPoolCreated(
            lendingPools[key],
            _debtToken,
            _collateralToken,
            _rate,
            _maturity,
            _maturityMonth,
            _maturityYear,
            _oracle
        );
        
        return lendingPools[key];
    }

    function getLendingPool(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string calldata _maturityMonth,
        uint256 _maturityYear
    ) external view returns (address) {
        string memory key = _generateKey(_debtToken, _collateralToken, _rate, _maturityMonth, _maturityYear);
        return lendingPools[key];
    }
}