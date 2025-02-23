// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DynamicOracle} from "../src/Oracle.sol";
import {DynamicOracleFactory} from "../src/OracleFactory.sol";

interface IOracle {
    function getPrice() external view returns(uint256);
}

contract DynamicOracleTest is Test {
    address constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

    DynamicOracle public dynamicOracle;
    DynamicOracleFactory public factory;
    IOracle public ioracle;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/Ea4M-V84UObD22z2nNlwDD9qP8eqZuSI", 21197642);
        
        // Deploy factory
        factory = new DynamicOracleFactory();
        
        address oracleAddress = factory.createOracle(ETH_USD_FEED, USDC_USD_FEED);
        ioracle = IOracle(oracleAddress);
    }

    function testGetPrice() public {
        uint256 price = ioracle.getPrice();
        assertGt(price, 0, "Price should be greater than zero");
        
        console.log("ETH/USDC Price:", price);
        
        assertGt(price, 1000 * 1e6, "ETH price too low");
        assertLt(price, 10000 * 1e6, "ETH price too high");
    }
}
