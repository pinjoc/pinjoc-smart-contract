// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Uint256Library} from "./types/Types.sol";

using Uint256Library for uint256;
using Strings for address;

contract OrderBookToken is ERC20 {

    constructor(
        address _token,
        string memory _maturityMonth,
        uint256 _maturityYear
    ) ERC20(_token.toHexString(), generateTokenSymbol(_token, _maturityMonth, _maturityYear)) {}

    function generateTokenSymbol(
        address _token,
        string memory _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                IERC20Metadata(_token).symbol(),
                _maturityMonth,
                _maturityYear.toString()
            )
        );
    }
}