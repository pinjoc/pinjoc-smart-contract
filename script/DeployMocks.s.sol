// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";

contract DeployMocks is DeployHelpers {
    function run() public {
        uint256 deployerKey = getDeployerKey();
        console.log("Deployer Key:", deployerKey);
        vm.startBroadcast(deployerKey);

        MockToken usdc = new MockToken("Mock USDC", "MUSDC", 6);
        console.log("MockUSDC deployed at:", address(usdc));

        MockToken weth = new MockToken("Mock WETH", "MWETH", 18);
        console.log("MockWETH deployed at:", address(weth));

        MockToken wbtc = new MockToken("Mock WBTC", "MWBTC", 8);
        console.log("MockWBTC deployed at:", address(wbtc));

        MockToken solana = new MockToken("Mock SOL", "MSOL", 18);
        console.log("Mock SOL deployed at:", address(solana));

        MockToken chainlink = new MockToken("Mock Chainlink", "MLINK", 18);
        console.log("MockChainlink deployed at:", address(chainlink));

        MockToken aave = new MockToken("Mock AAVE", "MAAVE", 18);
        console.log("Mock AAVE deployed at:", address(aave));

        // Mock Oracle
        MockOracle MWETHMUSD = new MockOracle(address(weth), address(usdc));
        MWETHMUSD.setPrice(2500e6);
        console.log("MockOracle MWETHMUSD deployed at:", address(MWETHMUSD));

        MockOracle MWBTCMUSDC = new MockOracle(address(wbtc), address(usdc));
        MWBTCMUSDC.setPrice(90000e6);
        console.log("MockOracle MWBTCMUSDC deployed at:", address(MWBTCMUSDC));

        MockOracle MSOLMUSDC = new MockOracle(address(solana), address(usdc));
        MSOLMUSDC.setPrice(200e6);
        console.log("MockOracle MSOLMUSDC deployed at:", address(MSOLMUSDC));

        MockOracle MLINKMUSDC = new MockOracle(
            address(chainlink),
            address(usdc)
        );
        MLINKMUSDC.setPrice(15e6);
        console.log("MockOracle MLINKMUSDC deployed at:", address(MLINKMUSDC));

        MockOracle MAAVEMUSDC = new MockOracle(address(aave), address(usdc));
        MAAVEMUSDC.setPrice(200e6);
        console.log("MockOracle MAAVEMUSDC deployed at:", address(MAAVEMUSDC));

        // Lending Pool Manager

        vm.stopBroadcast();

        exportDeployments();
    }
}
