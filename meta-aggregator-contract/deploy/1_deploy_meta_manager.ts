import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const MetaAggregatorSwapContract = await deployments.get("MetaAggregatorSwapContract");


  await deploy("MetaAggregatorManager", {
    from: deployer,
    contract: "MetaAggregatorManager",
    args: [MetaAggregatorSwapContract.address],
    log: true,
  });
};
export default func;
func.tags = ["MetaAggregatorManager"];