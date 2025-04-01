# Vulnerability Report: Hardcoded Oracle Expiration Threshold

## Description
The `PriceOracleAbstract` contract implements a hardcoded oracle expiration threshold of 25 hours for all Chainlink price feeds. This is problematic because different Chainlink price feeds have varying heartbeat intervals and update frequencies. Some feeds update as frequently as every hour, while others may update every 24 hours.

## Vulnerability Details
```solidity
constructor(address _WETH) {
    if (_WETH == address(0)) revert InvalidAddressError();
    WETH = _WETH;
    oracleExpirationThreshold = 25 hours; // Hardcoded threshold
}
```

The contract sets a universal 25-hour expiration threshold for all price feeds. This creates two potential issues:

1. For price feeds with shorter update frequencies (e.g., 1 hour), the 25-hour threshold is too lenient and allows extremely stale prices to be considered valid. This could lead to the acceptance of outdated price data in critical operations.

2. The hardcoded value doesn't account for the varying nature of different asset pairs and their specific market dynamics, which Chainlink has carefully considered in their individual heartbeat configurations.

## Impact
- **Price Staleness**: The system may accept stale prices that are up to 25 hours old, even for assets that should have much fresher price data.
- **Manipulation Risk**: Malicious actors could potentially exploit situations where price data is significantly outdated but still within the overly lenient threshold.
- **Inaccurate Valuations**: Protocol operations relying on price feeds might use stale data, leading to incorrect valuations or unfair trades.

## Recommendation
1. Make the expiration threshold configurable per price feed rather than using a global value:
```solidity
mapping(address => uint256) public feedExpirationThresholds;

function setFeedExpirationThreshold(address feed, uint256 threshold) external onlyOwner {
    feedExpirationThresholds[feed] = threshold;
    emit FeedExpirationThresholdUpdated(feed, threshold);
}
```

2. When adding new price feeds, require the appropriate threshold to be set based on the specific Chainlink feed's heartbeat:
```solidity
function setFeeds(
    address[] memory bases,
    address[] memory quotes,
    AggregatorV2V3Interface[] memory aggregators,
    uint256[] memory thresholds
) external onlyOwner {
    // ... existing checks ...
    for (uint256 i = 0; i < bases.length; i++) {
        // ... existing feed setup ...
        feedExpirationThresholds[address(aggregators[i])] = thresholds[i];
    }
}
```

## References
- [Chainlink Price Feeds](https://docs.chain.link/data-feeds)
- [Chainlink Heartbeat Documentation](https://docs.chain.link/architecture-overview/architecture-decentralized-model#heartbeat)
