import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy("MetaAggregatorSwapContract", {
    from: deployer,
    contract: "MetaAggregatorSwapContract",
    args: ["0x38147794FF247e5Fc179eDbAE6C37fff88f68C52"], // address of ensoSwap
    log: true,
  });
};
export default func;
func.tags = ["MetaAggregatorSwapContract"];