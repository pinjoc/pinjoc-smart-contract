// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.26;

// import {Script, console} from "forge-std/Script.sol";
// import {MockToken} from "../src/mocks/MockToken.sol";
// import {MockOracle} from "../src/mocks/MockOracle.sol";
// import {DeployHelpers} from "./DeployHelpers.s.sol";
// import {LendingPoolManager} from "../src/LendingPoolManager.sol";
// import {LendingPool} from "../src/LendingPool.sol";
// import {MockGTXOrderBook} from "../src/mocks/MockGTXOrderBook.sol";
// import {PinjocRouter} from "../src/PinjocRouter.sol";

// contract DeployMocks is DeployHelpers {
//     struct MonthRate {
//         string month;
//         uint64[2] rates;
//         uint256 year;
//     }

//     function saveDeployment(
//         string memory fileName,
//         address usdc,
//         MockToken collaterals,
//         address lendingPoolManager,
//         address pinjocRouter,
//         address mockGTXOrderBook,
//         LendingPool lendingPools,
//         MonthRate memory monthRates
//     ) internal {
//         string memory json = "{\n";

//         // Simpan Mock USDC Address
//         json = string.concat(
//             json,
//             '  "MockUSDC": "',
//             vm.toString(usdc),
//             '",\n'
//         );

//         // Simpan Collateral Token Addresses
//         json = string.concat(
//             json,
//             '  "',
//             collaterals.symbol(),
//             '": "',
//             vm.toString(address(collaterals)),
//             '",\n'
//         );

//         // Simpan LendingPoolManager & Router Addresses
//         json = string.concat(
//             json,
//             '  "LendingPoolManager": "',
//             vm.toString(lendingPoolManager),
//             '",\n'
//         );
//         json = string.concat(
//             json,
//             '  "MockGTXOrderBook": "',
//             vm.toString(mockGTXOrderBook),
//             '",\n'
//         );
//         json = string.concat(
//             json,
//             '  "PinjocRouter": "',
//             vm.toString(pinjocRouter),
//             '",\n'
//         );

//         // Simpan Semua Lending Pools
//         for (uint256 k = 0; k < 2; k++) {
//             json = string.concat(
//                 json,
//                 "    {\n",
//                 '      "Collateral": "',
//                 collaterals.symbol(),
//                 '",\n',
//                 '      "Month": "',
//                 monthRates.month,
//                 '",\n',
//                 '      "Rate": "',
//                 vm.toString(monthRates.rates[k]),
//                 '",\n',
//                 '      "Address": "',
//                 vm.toString(address(lendingPools)),
//                 '"\n',
//                 "    },\n"
//             );
//         }
//         // Hapus koma terakhir untuk JSON valid
//         json = string.concat(json, "  ]\n}");

//         // Simpan ke file JSON
//         vm.writeFile(fileName, json);
//     }

//     function run() public {
//         uint256 deployerKey = getDeployerKey();
//         address owner = vm.addr(deployerKey);
//         vm.startBroadcast(deployerKey);

//         console.log(unicode"\n🚀 DEPLOYMENT STARTED 🚀");

//         // Deploy Mock Tokens
//         console.log(unicode"🪙 Deploying Mock Tokens...");
//         MockToken musdc = new MockToken("Mock USDC", "MUSDC", 6);
//         console.log(unicode"✅ Mock USDC deployed at: %s", address(musdc));

//         MockToken collaterals = new MockToken("Mock WETH", "MWETH", 18);

//         console.log(
//             unicode"✅ %s deployed at: %s",
//             collaterals.symbol(),
//             address(collaterals)
//         );

//         // Mint Tokens to Owner (Tambahkan Likuiditas Lebih Banyak)
//         console.log(unicode"\n💰 Minting Tokens to Owner...");
//         musdc.mint(owner, 1_000_000_000e6);
//         console.log(unicode"✅ Minted 1B MUSDC");

//         uint88 mintAmounts = 50_000_000e18;
//         collaterals.mint(owner, mintAmounts);
//         console.log(
//             unicode"✅ Minted %s: %s",
//             collaterals.symbol(),
//             mintAmounts
//         );

//         // Deploy Mock Oracles
//         console.log(unicode"\n📊 Deploying Mock Oracles...");
//         MockOracle oracles;
//         uint32 prices = 2500e6;

//         oracles = new MockOracle(address(collaterals), address(musdc));
//         oracles.setPrice(prices);
//         console.log(
//             unicode"✅ MockOracle for %s deployed at: %s",
//             collaterals.symbol(),
//             address(oracles)
//         );

//         // Deploy LendingPoolManager
//         console.log(unicode"\n🏦 Deploying LendingPoolManager...");
//         LendingPoolManager lendingPoolManager = new LendingPoolManager();
//         lendingPoolManager.setLtv(90e16);
//         console.log(
//             unicode"✅ LendingPoolManager deployed at: %s",
//             address(lendingPoolManager)
//         );

//         // Deploy Lending Pools
//         console.log(unicode"\n📌 Deploying Lending Pools...");
//         LendingPool lendingPools;

//         MonthRate memory monthRates = MonthRate("MAY", [6e16, 8e16], 2025);
//         for (uint256 k = 0; k < 2; k++) {
//             lendingPools = LendingPool(
//                 lendingPoolManager.createLendingPool(
//                     address(musdc),
//                     address(collaterals),
//                     monthRates.rates[k],
//                     block.timestamp + 30 days,
//                     monthRates.month,
//                     monthRates.year,
//                     address(oracles)
//                 )
//             );
//             console.log(unicode"✅ LendingPool deployed:");
//             console.log("Collateral:", collaterals.symbol());
//             console.log("Month:", monthRates.month);
//             console.log("Rate:", monthRates.rates[k]);
//             console.log("Address:", address(lendingPools));

//             uint256 usdcSupply = 250_000e6;
//             uint256 collateralSupply = mintAmounts / 40; // Dibagi 40 agar cukup

//             // Supply USDC ke LendingPool
//             musdc.approve(address(lendingPools), usdcSupply);
//             lendingPools.supply(owner, usdcSupply);
//             console.log(
//                 unicode"✅ SUPPLY %s USDC to LendingPool %s-%d",
//                 usdcSupply,
//                 monthRates.month,
//                 monthRates.rates[k]
//             );

//             // Supply Collateral ke LendingPool
//             collaterals.approve(address(lendingPools), collateralSupply);
//             lendingPools.supplyCollateral(collateralSupply);
//             console.log(
//                 unicode"✅ SUPPLY_COLLATERAL %s to LendingPool %s-%d",
//                 collaterals.symbol(),
//                 monthRates.month,
//                 monthRates.rates[k]
//             );
//         }

//         console.log(unicode"\n🏦 Deploying MockGTXOrderBook...");
//         MockGTXOrderBook mockGTXOrderBook = new MockGTXOrderBook();
//         console.log(
//             unicode"✅ MockGTXOrderBook deployed at: %s",
//             address(mockGTXOrderBook)
//         );

//         console.log(unicode"\n🏦 Deploying PinjocRouter...");
//         PinjocRouter pinjocRouter = new PinjocRouter(
//             address(mockGTXOrderBook),
//             address(lendingPoolManager)
//         );
//         console.log(
//             unicode"✅ PinjocRouter deployed at: %s",
//             address(pinjocRouter)
//         );

//         console.log(unicode"\n🎉 DEPLOYMENT COMPLETED 🎉");
//         saveDeployment(
//             "./deployments.json",
//             address(musdc),
//             collaterals,
//             address(lendingPoolManager),
//             address(pinjocRouter),
//             address(mockGTXOrderBook),
//             lendingPools,
//             monthRates
//         );

//         vm.stopBroadcast();
//     }
// }
