// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IChainLink {
    function latestRoundData() external view 
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract Oracle {
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