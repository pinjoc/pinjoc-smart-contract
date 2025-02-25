// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Uint256Library} from "./types/Types.sol";

using Uint256Library for uint256;

contract PinjocToken is ERC20, Ownable {
    constructor(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _maturityMonth,
        uint256 _maturityYear,
        address _lendingPool
    ) ERC20(
        generateTokenName(_debtToken, _collateralToken, _rate, _maturityMonth, _maturityYear),
        generateTokenSymbol(_debtToken, _collateralToken, _rate, _maturityMonth, _maturityYear)
    ) Ownable(_lendingPool) {}

    function generateTokenName(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                "POC ",
                IERC20Metadata(_debtToken).symbol(), 
                "-", 
                IERC20Metadata(_collateralToken).symbol(),
                " ",
                _rate.toString(),
                "% ",
                _maturityMonth,
                "-",
                _maturityYear.toString()
            ) // POC ETH-USDC 4% MAR-2025
        );
    }

    function generateTokenSymbol(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                "poc",
                IERC20Metadata(_debtToken).symbol(),
                IERC20Metadata(_collateralToken).symbol(),
                _rate.toString(),
                _maturityMonth,
                _maturityYear.toString()
            ) // pocETHUSDC4MAR2025
        );
    }
    
    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}