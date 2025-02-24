// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Uint256Library} from "./types/Types.sol";

using Uint256Library for uint256;

contract POCToken is ERC20, Ownable {
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
    )
    Ownable(_lendingPool)
    {}

    function generateTokenName(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (string memory) {
        string memory pair = getTokenPair(_debtToken, _collateralToken);
        return string(
            abi.encodePacked(
                "POC ",
                pair,
                " ",
                _rate.toString(),
                "% ",
                _maturityMonth,
                "-",
                _maturityYear.toString()
            )
        );
    }

    function getTokenPair(address _debtToken, address _collateralToken) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                IERC20Metadata(_debtToken).symbol(), 
                "-", 
                IERC20Metadata(_collateralToken).symbol()
            )
        );
    }

    function generateTokenSymbol(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (string memory) {
        string memory pairSymbol = getTokenPairSymbol(_debtToken, _collateralToken);
        return string(
            abi.encodePacked(
                "poc",
                pairSymbol,
                _rate.toString(),
                _maturityMonth,
                _maturityYear.toString()
            )
        );
    }

    function getTokenPairSymbol(address _debtToken, address _collateralToken) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                IERC20Metadata(_debtToken).symbol(),
                IERC20Metadata(_collateralToken).symbol()
            )
        );
    }
    
    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}