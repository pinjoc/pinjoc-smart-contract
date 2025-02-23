// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {MonthMapping} from "./types/Mapping.sol";

// interface read symbol token ERC20
interface IERC20Symbol {
    function symbol() external view returns (string memory);
}

contract OrderBookToken is ERC20 {
    // error
    error InvalidMonth();

    // parameters
    address public token;
    uint256 public maturityMonth;
    uint256 public maturityYear;
    MonthMapping public monthMapping;

    constructor(
        address _monthMapping,
        address _token,
        string memory _month,
        uint256 _year
    ) ERC20(
        generateTokenName(_token),
        generateTokenSymbol(_token, _month, _year)
    ) {
        token = _token;
        monthMapping = _monthMapping;
        
        // set maturity
        uint256 monthNumber = monthMapping.getMonthNumber(_month);
        if (monthNumber == 0) revert InvalidMonth();
        maturityMonth = monthNumber;
        maturityYear = _year;
    }

    function generateTokenName(
        address _token
    ) internal view returns (string memory) {
        string memory symbol = getTokenPair(_token);
        return string(
            abi.encodePacked(
                "CA ",
                symbol
            )
        );
    }

    function generateTokenSymbol(
        address _token,
        string memory _month,
        uint256 _year
    ) internal view returns (string memory) {
        string memory symbol = getTokenPair(_token);
        return string(
            abi.encodePacked(
                symbol,
                _month,
                uint2str(_year)
            )
        );
    }

    function getTokenPair(address _token) internal view returns (string memory) {
        string memory tokenSymbol = IERC20Symbol(_token).symbol();
        return string(abi.encodePacked(tokenSymbol));
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 temp = _i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_i != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_i % 10)));
            _i /= 10;
        }
        return string(buffer);
    }
    
    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function getMaturityDate() public view returns (string memory, uint256) {
        return (monthMapping.getFullMonthName(maturityMonth), maturityYear);
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}