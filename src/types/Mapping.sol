// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MonthMapping {
    mapping(string => uint256) private monthToNumber;
    mapping(uint256 => string) private numberToMonth;
    mapping(uint256 => string) private numberToMonthShort;

    constructor() {
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
    }

    function getMonthNumber(string memory _month) external view returns (uint256) {
        return monthToNumber[_month];
    }

    function getFullMonthName(uint256 _number) external view returns (string memory) {
        return numberToMonth[_number];
    }

    function getShortMonthName(uint256 _number) external view returns (string memory) {
        return numberToMonthShort[_number];
    }
}
