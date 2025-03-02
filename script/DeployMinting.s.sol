// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";
import {MockToken} from "../src/mocks/MockToken.sol";

contract DeployMinting is DeployHelpers {
    function run() external {
        MockToken musdc = MockToken(0x0F848482cC12EA259DA229e7c5C4949EdA7E6475);
        MockToken[5] memory collaterals = [
            MockToken(0xa8014bB3A0020C0FF326Ef3AF3E1c55F6e5B25c7), // WETH
            MockToken(0xf14442CCE4511D0B5DC34425bceA50Ca67626c3a), // WBTC
            MockToken(0x12eC2c5144CF6feCCE8927cB1F748e9f60a97682), // SOL
            MockToken(0x19477F1e5515AF38E6C85F14C43DEb538d475524), // LINK
            MockToken(0x4b95Ba646c2Ed7fAB76e7C0a04245c61A9d4D686) // AAVE
        ];

        uint88[5] memory mintAmounts = [
            50_000_000e18, // MWETH
            50_000_000e8, // MWBTC
            50_000_000e18, // MSOL
            50_000_000e18, // MLINK
            50_000_000e18 // MAAVE
        ];

        address user = 0xeD08BD853B9a4Af46AB1689A209beac54f14f74E;

        musdc.mint(user, 1_000_000_000e6);
        for (uint256 i = 0; i < collaterals.length; i++) {
            collaterals[i].mint(user, mintAmounts[i]);
        }

        console.log("Minting done");
    }
}
