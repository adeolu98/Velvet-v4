import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import "@nomicfoundation/hardhat-chai-matchers";
import { ethers, network } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { IERC20__factory, BridgeContract } from "../../typechain";
import { chainIdToAddresses } from "../../scripts/networkVariables";

describe("BridgeContract Tests", () => {
  let accounts;
  let bridgeContract: BridgeContract;
  let owner: SignerWithAddress;
  let swapHandler: Contract;
  let nonOwner: SignerWithAddress;
  let treasury: SignerWithAddress;
  let assetManagerTreasury: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addrs: SignerWithAddress[];

  const provider = ethers.provider;
  const chainId: any = process.env.CHAIN_ID;
  const addresses = chainIdToAddresses[chainId];

  before(async () => {
    accounts = await ethers.getSigners();
    [owner, nonOwner, treasury, assetManagerTreasury, addr1, addr2, ...addrs] =
      accounts;

    // Deploy Bridge Contract
    const BridgeContract = await ethers.getContractFactory("BridgeContract");
    bridgeContract = await BridgeContract.deploy();
    await bridgeContract.deployed();

    // Deploy and initialize SwapHandler
    const SwapHandler = await ethers.getContractFactory("UniswapV2Handler");
    swapHandler = await SwapHandler.deploy();
    await swapHandler.deployed();
    await swapHandler.init(addresses.SushiSwapRouterAddress);

    console.log("Bridge deployed to:", bridgeContract.address);
    console.log("SwapHandler deployed to:", swapHandler.address);
  });

  describe("Bridge Tests", function () {
    it("should get initial balances and bridge USDC", async () => {
      const USDC = await ethers.getContractAt("IERC20", addresses.USDC);

      // Get initial balance
      const initialBalance = await USDC.balanceOf(owner.address);
      console.log("Initial USDC balance:", initialBalance.toString());

      // Swap ETH for USDC

      await swapHandler.swapETHToTokens(
        "500",
        addresses.USDC,
        bridgeContract.address,
        {
          value: ethers.utils.parseEther("0.5"),
        }
      );

      // Get balance after swap
      const balanceAfterSwap = await USDC.balanceOf(bridgeContract.address);
      console.log("USDC balance after swap:", balanceAfterSwap.toString());

      // Execute bridge with protocol fee
      const protocolFee = ethers.utils.parseEther("0.5"); // 0.1 ETH should be enough

      // Execute bridge with protocol fee
      const bridgeTx = await bridgeContract.bridge({
        value: protocolFee,
      });
      await bridgeTx.wait();

      // Get final balance
      const finalBalance = await USDC.balanceOf(bridgeContract.address);
      console.log("Final USDC balance:", finalBalance.toString());

      // Verify balance changes
      expect(balanceAfterSwap).to.be.gt(initialBalance);
      expect(finalBalance).to.be.lt(balanceAfterSwap);
    });
  });
});
