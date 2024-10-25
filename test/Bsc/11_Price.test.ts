import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("PythAggregatorTest and PriceOracle Tests", function () {
  let pythAggregator: Contract;
  let priceOracle: Contract;
  let owner: SignerWithAddress;

  const WETH_ADDRESS = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"; // WBNB address on BSC

  before(async function () {
    [owner] = await ethers.getSigners();

    console.log("Deploying PythAggregatorTest...");
    const PythAggregatorTest = await ethers.getContractFactory(
      "PythAggregatorTest"
    );
    pythAggregator = await PythAggregatorTest.deploy();
    await pythAggregator.deployed();
    console.log("PythAggregatorTest deployed to:", pythAggregator.address);

    console.log("Deploying PriceOracle...");
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    priceOracle = await PriceOracle.deploy(WETH_ADDRESS);
    await priceOracle.deployed();
    console.log("PriceOracle deployed to:", priceOracle.address);

    console.log("Setting feeds in PriceOracle...");
    await priceOracle.setFeeds(
      [WETH_ADDRESS],
      ["0x0000000000000000000000000000000000000348"], // USD address
      [pythAggregator.address]
    );
    console.log("Feeds set successfully");
  });

  describe("PythAggregatorTest", function () {
    it("should return the USD price for 1 ETH should be greater than 0", async function () {
      const answer = await pythAggregator.latestRoundData();
      expect(BigNumber.from(answer.answer).gt(BigNumber.from(0))).to.be.true;
    });
  });

  describe("PriceOracle with PythAggregatorTest", function () {
    it("should return a USD value for 1 ETH from PriceOracle", async function () {
      const oneEth = ethers.utils.parseEther("1");
      const usdValue = await priceOracle.convertToUSD18Decimals(
        WETH_ADDRESS,
        oneEth
      );

      expect(BigNumber.from(usdValue).gt(BigNumber.from(0))).to.be.true;
    });
  });
});
