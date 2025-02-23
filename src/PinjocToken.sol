// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// interface read symbol token ERC20
interface IERC20Symbol {
    function symbol() external view returns (string memory);
}

contract POCToken is ERC20 {
    // error
    error InvalidMonth();

    // parameters
    address public debtToken;
    address public collateralToken;
    uint256 public rate;
    uint256 public maturityMonth;
    uint256 public maturityYear;

    // mapping month
    mapping(string => uint256) public monthToNumber;
    mapping(uint256 => string) public numberToMonth;
    mapping(uint256 => string) public numberToMonthShort;

    constructor(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _month,
        uint256 _year
    ) ERC20(
        generateTokenName(_debtToken, _collateralToken, _rate, _month, _year),
        generateTokenSymbol(_debtToken, _collateralToken, _rate, _month, _year)
    ) {
        debtToken = _debtToken;
        collateralToken = _collateralToken;
        rate = _rate;

        // initialize month mapping
        monthToNumber["JAN"] = 1;
        monthToNumber["FEB"] = 2;
        monthToNumber["MAR"] = 3;
        monthToNumber["APR"] = 4;
        monthToNumber["MAY"] = 5;
        monthToNumber["JUN"] = 6;
        monthToNumber["JUL"] = 7;
        monthToNumber["AUG"] = 8;
        monthToNumber["SEP"] = 9;
        monthToNumber["OCT"] = 10;
        monthToNumber["NOV"] = 11;
        monthToNumber["DEC"] = 12;

        numberToMonth[1] = "JANUARY";
        numberToMonth[2] = "FEBRUARY";
        numberToMonth[3] = "MARCH";
        numberToMonth[4] = "APRIL";
        numberToMonth[5] = "MAY";
        numberToMonth[6] = "JUNE";
        numberToMonth[7] = "JULY";
        numberToMonth[8] = "AUGUST";
        numberToMonth[9] = "SEPTEMBER";
        numberToMonth[10] = "OCTOBER";
        numberToMonth[11] = "NOVEMBER";
        numberToMonth[12] = "DECEMBER";

        numberToMonthShort[1] = "JAN";
        numberToMonthShort[2] = "FEB";
        numberToMonthShort[3] = "MAR";
        numberToMonthShort[4] = "APR";
        numberToMonthShort[5] = "MAY";
        numberToMonthShort[6] = "JUN";
        numberToMonthShort[7] = "JUL";
        numberToMonthShort[8] = "AUG";
        numberToMonthShort[9] = "SEP";
        numberToMonthShort[10] = "OCT";
        numberToMonthShort[11] = "NOV";
        numberToMonthShort[12] = "DEC";

        // set maturity
        if (monthToNumber[_month] == 0) revert InvalidMonth();
        maturityMonth = monthToNumber[_month];
        maturityYear = _year;
    }

    function generateTokenName(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _month,
        uint256 _year
    ) internal view returns (string memory) {
        string memory pair = getTokenPair(_debtToken, _collateralToken);
        return string(
            abi.encodePacked(
                "POC ",
                pair,
                " ",
                uint2str(_rate),
                "% ",
                _month,
                "-",
                uint2str(_year)
            )
        );
    }

    function getTokenPair(address _debtToken, address _collateralToken) internal view returns (string memory) {
        string memory debtSymbol = IERC20Symbol(_debtToken).symbol();
        string memory collateralSymbol = IERC20Symbol(_collateralToken).symbol();
        return string(abi.encodePacked(debtSymbol,"-",collateralSymbol));
    }

    function generateTokenSymbol(
        address _debtToken,
        address _collateralToken,
        uint256 _rate,
        string memory _month,
        uint256 _year
    ) internal view returns (string memory) {
        string memory pairSymbol = getTokenPairSymbol(_debtToken, _collateralToken);
        return string(
            abi.encodePacked(
                "poc",
                pairSymbol,
                uint2str(_rate),
                _month,
                uint2str(_year % 100)
            )
        );
    }

    function getTokenPairSymbol(address _debtToken, address _collateralToken) internal view returns (string memory) {
        string memory debtSymbol = IERC20Symbol(_debtToken).symbol();
        string memory collateralSymbol = IERC20Symbol(_collateralToken).symbol();
        return string(abi.encodePacked(debtSymbol, collateralSymbol));
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
        return (numberToMonth[maturityMonth], maturityYear);
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}