// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/oracle/PriceOracleAbstract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";


contract TestPriceOracle is PriceOracleAbstract {
    constructor(address _WETH) PriceOracleAbstract(_WETH) {}

    // Mock implementation of _latestRoundData
    function _latestRoundData(
        address base,
        address quote
    ) internal view override returns (int256) {
        // Return a fixed price of $100,000 for WBTC/USD with 8 decimals (Chainlink standard)
        return 100_000 * 1e8; // $100,000.00000000
    }

    // // Mock implementation of decimals
    // function decimals(
    //     address base,
    //     address quote
    // ) public pure override returns (uint8) {
    //     return 8;
    //     // Chainlink WBTC/USD feed uses 8 decimals -> https://data.chain.link/feeds/arbitrum/mainnet/wbtc-usd,
    //     // https://arbiscan.io/address/0xd0C7101eACbB49F3deCcCc166d238410D6D46d57#readContract
    // }
}

contract ConvertToUSD18DecimalsPOC is Test {
    TestPriceOracle public oracle;
    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
   address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
   address wbtc_usd_arb_feed = 0xd0C7101eACbB49F3deCcCc166d238410D6D46d57;
    function setUp() public {
        // Deploy test oracle
        oracle = new TestPriceOracle(weth);

        //set feeds 
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        AggregatorV2V3Interface[] memory aggregators = new AggregatorV2V3Interface[](1);
        
        bases[0] = WBTC;
        quotes[0] = Denominations.USD;
        aggregators[0] = AggregatorV2V3Interface(wbtc_usd_arb_feed); // WBTC/USD  arb Feed
        
        oracle.setFeeds(bases, quotes, aggregators);
    }



    function testConvertToUSD18Decimals() public {
        // WBTC has 8 decimals
        uint8 wbtcDecimals = ERC20(WBTC).decimals();
        assertEq(wbtcDecimals, 8, "WBTC should have 8 decimals");

        // Get current WBTC/USD price from Chainlink
        (, int256 btcPrice, , , ) = AggregatorV2V3Interface(wbtc_usd_arb_feed).latestRoundData();
        uint8 btcPriceDecimals = AggregatorV2V3Interface(wbtc_usd_arb_feed).decimals();
        
        // Test with 1 WBTC
        uint256 amountIn = 1 * 10 ** wbtcDecimals; // 1 WBTC

        vm.expectRevert();
        uint256 amountOutUSD = oracle.convertToUSD18Decimals(WBTC, amountIn);

console.log("converted val:", amountOutUSD);
        //expect it to revert because convertToUSD18Decimals function logic 
        //will subtract 18 from the wbtcDecimals(8) i.e 8-18. 
        //This will result in a negative number which is not allowed in Solidity for uints

   }
}
