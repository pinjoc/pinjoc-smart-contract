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

contract DynamicOracle {
    // error
    error InvalidPrice();

    address public baseFeed;
    address public quoteFeed;

    constructor(address _baseFeed, address _quoteFeed) {
        baseFeed = _baseFeed;
        quoteFeed = _quoteFeed;
    }

    function updateFeed(address _newQuoteFeed, address _newBaseFeed) external {
        baseFeed = _newBaseFeed;
        quoteFeed = _newQuoteFeed;
    }

    function getPrice() public view returns (uint256) {
        (, int256 basePrice,,,) = IChainLink(baseFeed).latestRoundData();
        (, int256 quotePrice,,,) = IChainLink(quoteFeed).latestRoundData();
        if (basePrice < 0 || quotePrice < 0) revert InvalidPrice();
        return uint256(basePrice) * 1e6 / uint256(quotePrice);
    }
}