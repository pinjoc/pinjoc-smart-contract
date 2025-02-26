// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";
import {LendingPoolManager} from "../src/LendingPoolManager.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {MockGTXOrderBook} from "../src/mocks/MockGTXOrderBook.sol";
import {PinjocRouter} from "../src/PinjocRouter.sol";

contract DeployMocks is DeployHelpers {
    function run() public {
        uint256 deployerKey = getDeployerKey();
        address owner = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);

        console.log(unicode"\n🚀 DEPLOYMENT STARTED 🚀");

        // Deploy Mock Tokens
        console.log(unicode"🪙 Deploying Mock Tokens...");

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
        console.log(unicode"\n💰 Minting Tokens to Owner...");

        usdc.mint(owner, 10_000_000e6); // Mint lebih banyak USDC
        console.log(unicode"✅ Minted 10_000_000 MUSDC");

        uint88[5] memory mintAmounts = [
            10_000_000e18, // MWETH
            10_000_000e8, // MWBTC (8 desimal)
            10_000_000e18, // MSOL
            10_000_000e18, // MLINK
            10_000_000e18 // MAAVE
        ];

        for (uint256 i = 0; i < collaterals.length; i++) {
            collaterals[i].mint(owner, mintAmounts[i]);
            console.log(
                unicode"✅ Minted %s: %s",
                collaterals[i].symbol(),
                mintAmounts[i]
            );
        }

        // Deploy Mock Oracles
        console.log(unicode"\n📊 Deploying Mock Oracles...");

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
                address(oracles[i])
            );
        }

        // Deploy LendingPoolManager
        console.log(unicode"\n🏦 Deploying LendingPoolManager...");

        LendingPoolManager lendingPoolManager = new LendingPoolManager();
        lendingPoolManager.setLtv(90e16);
        console.log(
            unicode"✅ LendingPoolManager deployed at: %s",
            address(lendingPoolManager)
        );

        // Deploy Lending Pools
        console.log(unicode"\n📌 Deploying Lending Pools...");

        LendingPool[5] memory lendingPools;

        uint80[5] memory supplyAmounts = [
            1_000_000e18, // MWETH
            1_000_000e8, // MWBTC (8 desimal)
            1_000_000e18, // MSOL
            1_000_000e18, // MLINK
            1_000_000e18 // MAAVE
        ];

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

            // Approve MUSDC untuk supply
            usdc.approve(address(lendingPools[i]), 2_000_000e6); // Memberikan allowance yang lebih besar
            lendingPools[i].supply(owner, 1_000_000e6);
            console.log(
                unicode"✅ SUPPLY MUSDC ke LendingPool %s sebesar 1_000_000e6",
                months[i]
            );

            // Approve & Supply Collateral ke LendingPool
            collaterals[i].approve(address(lendingPools[i]), supplyAmounts[i]); // Approve hanya collateral yang sesuai
            lendingPools[i].supplyCollateral(supplyAmounts[i]);
            console.log(
                unicode"✅ SUPPLY_COLLATERAL %s ke LendingPool %s sebesar %s",
                collaterals[i].symbol(),
                months[i],
                supplyAmounts[i]
            );
        }

        console.log(unicode"\n🏦 Deploying MockGTXOrderBook...");
        MockGTXOrderBook mockGTXOrderBook = new MockGTXOrderBook();
        console.log(
            unicode"✅ MockGTXOrderBook deployed at: %s",
            address(mockGTXOrderBook)
        );

        console.log(unicode"\n🏦 Deploying PinjocRouter...");
        PinjocRouter pinjocRouter = new PinjocRouter(
            address(mockGTXOrderBook),
            address(lendingPoolManager)
        );
        console.log(
            unicode"✅ PinjocRouter deployed at: %s",
            address(pinjocRouter)
        );

        console.log(unicode"\n🎉 DEPLOYMENT COMPLETED 🎉");

        vm.stopBroadcast();
        exportDeployments();
    }
}
