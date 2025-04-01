// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/oracle/PriceOracleAbstract.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";

contract MockChainlinkAggregator is AggregatorV2V3Interface {
    int256 private _answer;
    uint256 private _updatedAt;
    uint80 private _roundId;
    mapping(uint256 => int256) private answers;
    mapping(uint256 => uint256) private timestamps;

    function setAnswer(int256 answer) external {
        _answer = answer;
    }

    function setUpdatedAt(uint256 updatedAt) external {
        _updatedAt = updatedAt;
    }

    function setRoundId(uint80 roundId) external {
        _roundId = roundId;
    }

    function setHistoricalAnswer(uint256 roundId, int256 answer, uint256 timestamp) external {
        answers[roundId] = answer;
        timestamps[roundId] = timestamp;
    }

    // AggregatorInterface implementations
    function latestAnswer() external view override returns (int256) {
        return _answer;
    }

    function latestTimestamp() external view override returns (uint256) {
        return _updatedAt;
    }

    function latestRound() external view override returns (uint256) {
        return _roundId;
    }

    function getAnswer(uint256 roundId) external view override returns (int256) {
        return answers[roundId];
    }

    function getTimestamp(uint256 roundId) external view override returns (uint256) {
        return timestamps[roundId];
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, block.timestamp, _updatedAt, _roundId);
    }

    // Required interface implementations
    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "Mock Aggregator";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80)
        external
        pure
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, 0, 0, 0);
    }
}

contract TestPriceOracle is PriceOracleAbstract {
    constructor(address _WETH) PriceOracleAbstract(_WETH) {}

    function _latestRoundData(
        address base,
        address quote
    ) internal view override returns (int256) {
        (, int256 answer, , uint256 updatedAt, ) = tokenPairToAggregator[base]
            .aggregators[quote]
            .latestRoundData();

        // Check if the price data is expired using the 25-hour threshold
        if (updatedAt + oracleExpirationThreshold < block.timestamp)
            revert ("Price Oracle Expired");

        if (answer <= 0) revert ("Price Oracle Invalid");

        return answer;
    }
}

contract PriceOracleStalePriceTest is Test {
    TestPriceOracle public oracle;
    MockChainlinkAggregator public ethUsdAggregator;
    MockChainlinkAggregator public btcUsdAggregator;
    
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    
    function setUp() public {
        // Deploy oracle and mock aggregators
        oracle = new TestPriceOracle(WETH);
        ethUsdAggregator = new MockChainlinkAggregator();
        btcUsdAggregator = new MockChainlinkAggregator();

        // Setup price feeds
        address[] memory bases = new address[](2);
        address[] memory quotes = new address[](2);
        AggregatorV2V3Interface[] memory aggregators = new AggregatorV2V3Interface[](2);

        bases[0] = WETH;
        bases[1] = WBTC;
        quotes[0] = Denominations.USD; // USD
        quotes[1] = Denominations.USD; // USD
        aggregators[0] = ethUsdAggregator;
        aggregators[1] = btcUsdAggregator;

        oracle.setFeeds(bases, quotes, aggregators);
    }

    function testStalePriceAcceptance() public {
        // Set initial prices
        ethUsdAggregator.setAnswer(2000e8); // $2000 per ETH
        btcUsdAggregator.setAnswer(30000e8); // $30000 per BTC
        
        // Set last update time to now
        uint256 currentTime = block.timestamp;
        ethUsdAggregator.setUpdatedAt(currentTime);
        btcUsdAggregator.setUpdatedAt(currentTime);

        // This should work - prices are fresh
        oracle.convertToUSD18Decimals(WETH, 1e18); // Convert 1 ETH to USD
        oracle.convertToUSD18Decimals(WBTC, 1e8);  // Convert 1 BTC to USD

        // Simulate time passing - 4 hours
        vm.warp(currentTime + 4 hours);

        // ETH price feed (1hr heartbeat) should revert as it's stale
        // But it doesn't because of the 25hr threshold
        uint256 ethPrice = oracle.convertToUSD18Decimals(WETH, 1e18);
        assertEq(ethPrice, 2000e18, "ETH price should be $2000");

        // Even after 20 hours (way beyond ETH's 1hr heartbeat)
        vm.warp(currentTime + 20 hours);
        ethPrice = oracle.convertToUSD18Decimals(WETH, 1e18);
        assertEq(ethPrice, 2000e18, "ETH price still accepted despite being 20hrs stale");

        // Only reverts after 25 hours
        vm.warp(currentTime + 26 hours);
        vm.expectRevert("Price Oracle Expired");
        oracle.convertToUSD18Decimals(WETH, 1e18);
    }

    function testPriceManipulationScenario() public {
        // Initial setup
        ethUsdAggregator.setAnswer(2000e8); // $2000 per ETH
        uint256 currentTime = block.timestamp;
        ethUsdAggregator.setUpdatedAt(currentTime);

        // Simulate a flash crash where ETH drops to $1500
        vm.warp(currentTime + 30 minutes);
        ethUsdAggregator.setAnswer(1500e8);
        ethUsdAggregator.setUpdatedAt(currentTime + 30 minutes);

        // Chainlink oracle goes down for maintenance or network issues
        // Price stays at $1500 but time passes...
        vm.warp(currentTime + 20 hours);

        // Despite the price being 20 hours old (way beyond ETH's typical 1hr heartbeat)
        // The protocol still accepts this price due to 25hr threshold
        uint256 ethPrice = oracle.convertToUSD18Decimals(WETH, 1e18);
        assertEq(ethPrice, 1500e18, "Stale crash price still accepted after 20 hours");

        // In reality, ETH could have recovered to $2000 hours ago
        // But the protocol would still use the stale $1500 price
        // This could be exploited in various ways:
    }
}
