// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ChainLink: https://data.chain.link/feeds
// https://data.chain.link/feeds/ethereum/mainnet/eth-usd
// https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
// Retrieve the contract function

// Retrieve USDC to USD as well, since eth-usd is not using USDC

interface IChainLink {
    function latestRoundData() external view 
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract ETHUSDOracle {
    
    address baseFeeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH-USD
    address quoteFeed = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // USDC-USD

    function getPrice() public view returns (uint256) {
        (, int256 ethPrice,,,) = IChainLink(baseFeeed).latestRoundData();
        (, int256 usdPrice,,,) = IChainLink(quoteFeed).latestRoundData();

        return uint256(ethPrice) * 1e6 / uint256(usdPrice);
    }
}