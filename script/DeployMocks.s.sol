// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";
import {LendingPoolManager} from "../src/LendingPoolManager.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {PinjocRouter} from "../src/PinjocRouter.sol";
import {LendingOrderType} from "../src/types/Types.sol";

contract DeployMocks is DeployHelpers {
    function saveDeploymentToFile(
        address musdc,
        address[] memory collateralAddresses,
        address[] memory oracleAddresses,
        address lendingPoolManager,
        address pinjocRouter,
        address[] memory lendingPools
    ) internal {
        string memory json = "{\n";
        json = string(
            abi.encodePacked(json, '  "musdc": "', toHexString(musdc), '",\n')
        );

        json = string(abi.encodePacked(json, '  "collaterals": [\n'));
        for (uint256 i = 0; i < collateralAddresses.length; i++) {
            json = string(
                abi.encodePacked(
                    json,
                    '    "',
                    toHexString(collateralAddresses[i]),
                    '"'
                )
            );
            if (i < collateralAddresses.length - 1)
                json = string(abi.encodePacked(json, ",\n"));
        }
        json = string(abi.encodePacked(json, "\n  ],\n"));

        json = string(abi.encodePacked(json, '  "oracles": [\n'));
        for (uint256 i = 0; i < oracleAddresses.length; i++) {
            json = string(
                abi.encodePacked(
                    json,
                    '    "',
                    toHexString(oracleAddresses[i]),
                    '"'
                )
            );
            if (i < oracleAddresses.length - 1)
                json = string(abi.encodePacked(json, ",\n"));
        }
        json = string(abi.encodePacked(json, "\n  ],\n"));

        json = string(
            abi.encodePacked(
                json,
                '  "lendingPoolManager": "',
                toHexString(lendingPoolManager),
                '",\n'
            )
        );
        json = string(
            abi.encodePacked(
                json,
                '  "pinjocRouter": "',
                toHexString(pinjocRouter),
                '",\n'
            )
        );

        json = string(abi.encodePacked(json, '  "lendingPools": [\n'));
        for (uint256 i = 0; i < lendingPools.length; i++) {
            json = string(
                abi.encodePacked(
                    json,
                    '    "',
                    toHexString(lendingPools[i]),
                    '"'
                )
            );
            if (i < lendingPools.length - 1)
                json = string(abi.encodePacked(json, ",\n"));
        }
        json = string(abi.encodePacked(json, "\n  ]\n}"));

        vm.writeFile("deployments.json", json);
        console.log(unicode"✅ Deployment saved to deployments.json");
    }

    function toHexString(
        address _address
    ) internal pure returns (string memory) {
        return vm.toString(_address);
    }

    function run() public {
        uint256 deployerKey = getDeployerKey();
        address owner = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);

        console.log(unicode"\n🚀 DEPLOYMENT STARTED 🚀");

        // Deploy Mock Tokens
        console.log(unicode"🪙 Deploying Mock Tokens...");
        MockToken musdc = MockToken(0x0F848482cC12EA259DA229e7c5C4949EdA7E6475);
        console.log(unicode"✅ Mock USDC deployed at: %s", address(musdc));

        MockToken[5] memory collaterals = [
            MockToken(0xa8014bB3A0020C0FF326Ef3AF3E1c55F6e5B25c7),
            MockToken(0xf14442CCE4511D0B5DC34425bceA50Ca67626c3a),
            MockToken(0x12eC2c5144CF6feCCE8927cB1F748e9f60a97682),
            MockToken(0x19477F1e5515AF38E6C85F14C43DEb538d475524),
            MockToken(0x4b95Ba646c2Ed7fAB76e7C0a04245c61A9d4D686)
        ];

        address[] memory collateralAddresses = new address[](
            collaterals.length
        );
        address[] memory oracleAddresses = new address[](collaterals.length);
        address[] memory lendingPoolAddresses = new address[](
            collaterals.length
        );

        for (uint256 i = 0; i < collaterals.length; i++) {
            console.log(
                unicode"✅ %s deployed at: %s",
                collaterals[i].symbol(),
                address(collaterals[i])
            );
        }

        // Mint Tokens to Owner
        console.log(unicode"\n💰 Minting Tokens to Owner...");
        musdc.mint(owner, 1_000_000_000e6);
        console.log(unicode"✅ Minted 1B MUSDC");

        uint88[5] memory mintAmounts = [
            50_000_000e18, // MWETH
            50_000_000e8, // MWBTC
            50_000_000e18, // MSOL
            50_000_000e18, // MLINK
            50_000_000e18 // MAAVE
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

        for (uint256 i = 0; i < collaterals.length; i++) {
            oracles[i] = new MockOracle(
                address(collaterals[i]),
                address(musdc)
            );
            oracles[i].setPrice(prices[i]);
            console.log(
                unicode"✅ MockOracle for %s deployed at: %s",
                collaterals[i].symbol(),
                address(oracles[i])
            );
        }

        // Minting otomatis ke wallet testnet
        address[1] memory testWallets = [
            0x4176377dA5287Ec4eE6e60b1cA16210FC0Ab27FA
        ];

        uint256 mintAmountMusdc = 10_000e6;
        uint256 mintAmountCollateral = 5e18;

        console.log(unicode"\n💰 Minting Tokens to Test Wallets...");
        for (uint256 i = 0; i < testWallets.length; i++) {
            musdc.mint(testWallets[i], mintAmountMusdc);
            console.log(
                unicode"✅ Minted %s MUSDC to %s",
                mintAmountMusdc,
                testWallets[i]
            );

            for (uint256 j = 0; j < collaterals.length; j++) {
                collaterals[j].mint(testWallets[i], mintAmountCollateral);
                console.log(
                    unicode"✅ Minted %s %s to %s",
                    mintAmountCollateral,
                    collaterals[j].symbol(),
                    testWallets[i]
                );
            }
        }

        // Deploy LendingPoolManager
        console.log(unicode"\n🏦 Deploying LendingPoolManager...");
        LendingPoolManager lendingPoolManager = new LendingPoolManager();
        lendingPoolManager.setLtv(90e16);
        console.log(
            unicode"✅ LendingPoolManager deployed at: %s",
            address(lendingPoolManager)
        );

        console.log(unicode"\n🏦 Deploying PinjocRouter...");
        PinjocRouter pinjocRouter = new PinjocRouter(
            address(lendingPoolManager)
        );
        console.log(
            unicode"✅ PinjocRouter deployed at: %s",
            address(pinjocRouter)
        );

        // Approve Tokens
        console.log(unicode"\n🔑 Approving MUSDC for PinjocRouter...");
        musdc.approve(address(pinjocRouter), type(uint256).max);
        console.log(unicode"✅ Approved MUSDC for PinjocRouter");

        console.log(unicode"\n🔑 Approving Tokens for LendingPoolManager...");
        musdc.approve(address(lendingPoolManager), type(uint256).max);

        // Deploy Lending Pools and Place Orders
        LendingPool[] memory lendingPools = new LendingPool[](
            collaterals.length
        );

        // Calculate required collateral (Added 10% buffer)
        uint256 requiredCollateral = 1e18;

        collaterals[0].mint(owner, requiredCollateral);
        console.log("Owner MWETH Balance: %s", collaterals[0].balanceOf(owner));

        collaterals[0].approve(address(pinjocRouter), type(uint256).max);
        console.log(
            unicode"✅ Approved %s for PinjocRouter",
            collaterals[0].symbol()
        );

        collaterals[0].approve(address(lendingPoolManager), type(uint256).max);
        console.log(
            unicode"✅ Approved %s for LendingPoolManager",
            collaterals[0].symbol()
        );

        console.log(unicode"\n📌 createOrderBook...");
        pinjocRouter.createOrderBook(
            address(musdc),
            address(collaterals[0]),
            "MAY",
            2025
        );

        console.log(unicode"\n📌 Deploying Lending Pools...");
        lendingPools[0] = LendingPool(
            lendingPoolManager.createLendingPool(
                address(pinjocRouter),
                address(musdc),
                address(collaterals[0]),
                5e16,
                block.timestamp + 90 days,
                "MAY",
                2025,
                address(oracles[0])
            )
        );

        console.log(unicode"\n📌 placeOrder...");

        // Place Lending Order
        pinjocRouter.placeOrder(
            address(musdc),
            address(collaterals[0]),
            1000e6,
            0,
            7e16, // 5% APY
            block.timestamp + 90 days,
            "MAY",
            2025,
            LendingOrderType.LEND
        );

        // Place Borrow Order (With Fixed Collateral Calculation)
        pinjocRouter.placeOrder(
            address(musdc),
            address(collaterals[0]),
            2000e6,
            requiredCollateral,
            5e16, // 5% APY
            block.timestamp + 90 days,
            "MAY",
            2025,
            LendingOrderType.BORROW
        );

        console.log(unicode"\n🎉 DEPLOYMENT COMPLETED 🎉");
        for (uint256 i = 0; i < collaterals.length; i++) {
            collateralAddresses[i] = address(collaterals[i]);
            oracleAddresses[i] = address(oracles[i]);
            lendingPoolAddresses[i] = address(lendingPools[i]);
        }
        saveDeploymentToFile(
            address(musdc),
            collateralAddresses,
            oracleAddresses,
            address(lendingPoolManager),
            address(pinjocRouter),
            lendingPoolAddresses
        );
        vm.stopBroadcast();
    }
}
