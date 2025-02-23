// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {POCToken} from "../src/PinjocToken.sol";

contract POCTokenTest is Test {
    POCToken public pocToken;
    
    // Mainnet token addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    // Test parameters
    uint256 public rate;
    string public month;
    uint256 public year;
    
    function setUp() public {
        console.log("Setting up test environment...");
        console.log("Using mainnet addresses:");
        console.log("WETH address:", WETH);
        console.log("USDC address:", USDC);
        
        // Set test parameters
        rate = 4;
        month = "MAR";
        year = 2025;
        
        // Fork mainnet
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/Ea4M-V84UObD22z2nNlwDD9qP8eqZuSI",21197642);

        // Deploy POCToken
        pocToken = new POCToken(
            WETH,
            USDC,
            rate,
            month,
            year
        );
        
        console.log("POCToken deployed at:", address(pocToken));
    }
    
    function testTokenNameAndSymbol() public view {
        console.log("\nTesting token name and symbol...");
        
        // Expected values
        string memory expectedName = "POC WETH-USDC 4% MAR-2025";
        string memory expectedSymbol = "pocWETHUSDC4MAR2025";
        
        // Get actual values
        string memory actualName = pocToken.name();
        string memory actualSymbol = pocToken.symbol();
        
        console.log("Expected name:", expectedName);
        console.log("Actual name:", actualName);
        console.log("Expected symbol:", expectedSymbol);
        console.log("Actual symbol:", actualSymbol);
        
        // Assert
        assertEq(actualName, expectedName, "Token name should match expected value");
        assertEq(actualSymbol, expectedSymbol, "Token symbol should match expected value");
    }
    
    function testMinting() public {
        console.log("\nTesting minting functionality...");
        address user = address(1);
        uint256 amount = 1000 * 10**18;
        
        console.log("Minting to address:", user);
        //console.log("Amount before decimals:", 1000);
        console.log("Amount with decimals:", amount);
        
        // Get balance before minting
        uint256 balanceBefore = pocToken.balanceOf(user);
        console.log("Balance before minting:", balanceBefore);
        
        // Mint tokens
        pocToken.mint(user, amount);
        
        // Check balance after minting
        uint256 balanceAfter = pocToken.balanceOf(user);
        console.log("Balance after minting:", balanceAfter);
        
        assertEq(balanceAfter, amount, "User balance should match minted amount");
    }
}