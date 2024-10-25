// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import "hardhat/console.sol";

contract PythAggregatorTest {
  IPyth public pyth;
  bytes32 public constant ETH_USD_PRICE_ID =
    bytes32(0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace);

  uint256 public decimals = 18;

  constructor() {
    pyth = IPyth(0x4D7E825f80bDf85e913E0DD2A2D54927e9dE1594);
  }

  function latestRoundData()
    public
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    PythStructs.Price memory price = pyth.getPriceUnsafe(ETH_USD_PRICE_ID);

    console.log("before fetching the price");

    // Convert price to 8 decimal places (Chainlink standard)
    int256 ethUsdPrice = int256(
      (uint(uint64(price.price)) * (10 ** 18)) /
        (10 ** uint8(uint32(-1 * price.expo)))
    );

    console.log("price");
    console.log(uint256(ethUsdPrice));

    // Get the publish time
    //uint256 publishTime = uint256(price.publishTime);
    uint256 publishTime = block.timestamp;

    return (
      1, // roundId
      ethUsdPrice, // answer
      publishTime, // startedAt
      publishTime, // updatedAt
      1 // answeredInRound
    );
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
}
