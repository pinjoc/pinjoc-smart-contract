// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";
import {LendingPoolManager} from "../src/LendingPoolManager.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract DeployMocks is DeployHelpers {
    function run() public {
        uint256 deployerKey = getDeployerKey();
        address owner = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);

        console.log(unicode"\n🚀 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        console.log(unicode"🚀  DEPLOYMENT STARTED");
        console.log(unicode"🚀 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

        // Deploy Mock Tokens
        console.log(unicode"🪙 ──────────────────────────────────────");
        console.log(unicode"🪙  DEPLOYING MOCK TOKENS");
        console.log(unicode"🪙 ──────────────────────────────────────");

        MockToken usdc = new MockToken("Mock USDC", "MUSDC", 6);
        console.log(unicode"✅ Mock USDC deployed at: %s", address(usdc));

        MockToken[5] memory collaterals = [
            new MockToken("Mock WETH", "MWETH", 18),
            new MockToken("Mock WBTC", "MWBTC", 8),
            new MockToken("Mock SOL", "MSOL", 18),
            new MockToken("Mock Chainlink", "MLINK", 18),
            new MockToken("Mock AAVE", "MAAVE", 18)
        ];

        for (uint256 i = 0; i < collaterals.length; i++) {
            console.log(
                unicode"✅ %s deployed at: %s",
                collaterals[i].symbol(),
                address(collaterals[i])
            );
        }

        // Mint Tokens to Owner
        console.log(unicode"\n💰 ──────────────────────────────────────");
        console.log(unicode"💰  MINT KE OWNER");
        console.log(unicode"💰 ──────────────────────────────────────");

        usdc.mint(owner, 8_000_000e6);
        console.log(unicode"✅ MINT KE OWNER MUSDC SEBESAR 8_000_000e6");

        uint88[5] memory mintAmounts = [
            8_000_000e18,
            8_000_000e8,
            8_000_000e18,
            8_000_000e18,
            8_000_000e18
        ];

        for (uint256 i = 0; i < collaterals.length; i++) {
            collaterals[i].mint(owner, mintAmounts[i]);
            console.log(
                unicode"✅ MINT KE OWNER %s SEBESAR %s",
                collaterals[i].symbol(),
                mintAmounts[i]
            );
        }

        // Deploy Mock Oracles
        console.log(unicode"\n📊 ──────────────────────────────────────");
        console.log(unicode"📊  DEPLOYING MOCK ORACLES");
        console.log(unicode"📊 ──────────────────────────────────────");

        MockOracle[5] memory oracles;
        uint40[5] memory prices = [2500e6, 90000e6, 200e6, 15e6, 200e6];
        string[5] memory months = [
            "MAY",
            "JUNE",
            "JULY",
            "AUGUST",
            "SEPTEMBER"
        ];
        uint56[5] memory rates = [5e16, 6e16, 7e16, 4e16, 5e16];

        for (uint256 i = 0; i < collaterals.length; i++) {
            oracles[i] = new MockOracle(address(collaterals[i]), address(usdc));
            oracles[i].setPrice(prices[i]);
            console.log(
                unicode"✅ MockOracle for %s deployed at: %s",
                months[i],
                address(oracles[i])
            );
        }

        // Deploy LendingPoolManager
        console.log(unicode"\n🏦 ──────────────────────────────────────");
        console.log(unicode"🏦  DEPLOYING LENDINGPOOL MANAGER");
        console.log(unicode"🏦 ──────────────────────────────────────");

        LendingPoolManager lendingPoolManager = new LendingPoolManager();
        lendingPoolManager.setLtv(90e16);
        console.log(
            unicode"✅ LendingPoolManager deployed at: %s",
            address(lendingPoolManager)
        );

        // Deploy Lending Pools
        console.log(unicode"\n📌 ──────────────────────────────────────");
        console.log(unicode"📌  DEPLOYING LENDING POOLS");
        console.log(unicode"📌 ──────────────────────────────────────");

        LendingPool[5] memory lendingPools;

        for (uint256 i = 0; i < collaterals.length; i++) {
            lendingPools[i] = LendingPool(
                lendingPoolManager.createLendingPool(
                    address(usdc),
                    address(collaterals[i]),
                    rates[i],
                    block.timestamp + ((i + 1) * 30 days),
                    months[i],
                    2025,
                    address(oracles[i])
                )
            );
            console.log(
                unicode"✅ LendingPool USDC-%s deployed at: %s",
                months[i],
                address(lendingPools[i])
            );
        }

        console.log(unicode"\n🎉 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        console.log(unicode"🎉  DEPLOYMENT COMPLETED");
        console.log(unicode"🎉 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

        vm.stopBroadcast();
        exportDeployments();
    }
}
