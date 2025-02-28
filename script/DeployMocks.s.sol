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

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeployMocks is DeployHelpers {

    function run() public {
        uint256 deployerKey = getDeployerKey();
        address owner = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);

        console.log(unicode"\n🚀 DEPLOYMENT STARTED 🚀");

        // Deploy Mock Tokens
        console.log(unicode"🪙 Deploying Mock Tokens...");
        MockToken musdc = MockToken(0x0F848482cC12EA259DA229e7c5C4949EdA7E6475); // USDC
        console.log(unicode"✅ Mock USDC deployed at: %s", address(musdc));

        MockToken[5] memory collaterals = [
            MockToken(0xa8014bB3A0020C0FF326Ef3AF3E1c55F6e5B25c7), // WETH
            MockToken(0xf14442CCE4511D0B5DC34425bceA50Ca67626c3a), // WBTC
            MockToken(0x12eC2c5144CF6feCCE8927cB1F748e9f60a97682), // SOL
            MockToken(0x19477F1e5515AF38E6C85F14C43DEb538d475524), // LINK
            MockToken(0x4b95Ba646c2Ed7fAB76e7C0a04245c61A9d4D686)  // AAVE
        ];

        string[5] memory collateralSymbols = ["WETH", "WBTC", "SOL", "LINK", "AAVE"];
        for (uint256 i = 0; i < collaterals.length; i++) {
            console.log(
                unicode"✅ %s deployed at: %s",
                collateralSymbols[i],
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
        address[2] memory testWallets = [
            0xEa737Db924BA80639cbab7609570F3127e1a2Be7,
            0x116De0cDA2b985797bc24c899a697cEb2f72B445
        ];

        uint256 mintAmountMusdc = 10_000e6;
        uint256 mintAmountCollateral = 5000e18;
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

        string[4] memory maturityMonth = ["MAY", "AUG", "NOV", "FEB"];
        uint256[4] memory maturityYear = [uint256(2025), uint256(2025), uint256(2025), uint256(2026)];
        uint256[2][4] memory rate = [
            [uint256(5e16), uint256(7e16)],
            [uint256(10e16), uint256(12e16)],
            [uint256(19e16), uint256(21e16)],
            [uint256(26e16), uint256(30e16)]
        ];
        uint256[5] memory collateralAmount = [
            uint256(100e18),    // WETH
            uint256(100e8),     // WBTC 
            uint256(1000e18),   // SOL
            uint256(10_000e18), // LINK
            uint256(1000e18)    // AAVE
        ];

        console.log(unicode"\n🏦 Deploying PinjocRouter...");
        PinjocRouter pinjocRouter = new PinjocRouter(address(lendingPoolManager));
        console.log(
            unicode"✅ PinjocRouter deployed at: %s",
            address(pinjocRouter)
        );

        for (uint256 i = 0; i < collaterals.length; i++) {
            for (uint256 j = 0; j < maturityMonth.length; j++) {

                console.log(unicode"\n📌 createOrderBook...");
                pinjocRouter.createOrderBook(
                    address(musdc),
                    address(collaterals[i]),
                    maturityMonth[j],
                    maturityYear[j]
                );

                console.log(unicode"\n📌 createLendingPool...");
                lendingPoolManager.createLendingPool(
                    address(pinjocRouter),
                    address(musdc),
                    address(collaterals[i]),
                    5e16,
                    block.timestamp + ((j+1) * 90 days),
                    maturityMonth[j],
                    maturityYear[j],
                    address(oracles[i])
                );

                console.log(unicode"\n📌 placeOrder BORROW...");
                pinjocRouter.placeOrder(
                    address(musdc),
                    address(collaterals[i]),
                    10_000e6,
                    collateralAmount[i],
                    rate[j][0],
                    block.timestamp + ((j+1) * 90 days),
                    maturityMonth[j],
                    maturityYear[j],
                    LendingOrderType.BORROW
                );

                console.log(unicode"\n📌 placeOrder LEND...");
                pinjocRouter.placeOrder(
                    address(musdc),
                    address(collaterals[i]),
                    10_000e6,
                    0,
                    rate[j][1],
                    block.timestamp + ((j+1) * 90 days),
                    maturityMonth[j],
                    maturityYear[j],
                    LendingOrderType.LEND
                );
            }
        }

        console.log(unicode"\n🎉 DEPLOYMENT COMPLETED 🎉");

        vm.stopBroadcast();
    }
}
