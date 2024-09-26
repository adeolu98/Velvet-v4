// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades, tenderly } = require("hardhat");
const { chainIdToAddresses } = require("../scripts/networkVariables");

async function main() {
  let owner;
  let treasury;
  let accounts = await ethers.getSigners();
  [owner, treasury] = accounts;

  const forkChainId: any = process.env.CHAIN_ID;
  const chainId: any = process.env.CHAIN_ID;
  const addresses = chainIdToAddresses[chainId];

  // Set maximum gas fee (in Gwei)
  const MAX_GAS_FEE_GWEI = 10; // Adjust this value as needed
  
  // Get the current base fee
  const feeData = await ethers.provider.getFeeData();
  const baseFee = feeData.lastBaseFeePerGas;
  
  // Calculate priority fee (tip)
  const priorityFee = ethers.utils.parseUnits("1.5", "gwei");
  
  // Ensure the priority fee is at least 1 Gwei
  const minPriorityFee = ethers.utils.parseUnits("1", "gwei");
  const adjustedPriorityFee = priorityFee.lt(minPriorityFee) ? minPriorityFee : priorityFee;
  
  // Calculate max fee per gas, but cap it at MAX_GAS_FEE_GWEI
  const calculatedMaxFee = baseFee.mul(2).add(adjustedPriorityFee);
  const maxFeePerGas = calculatedMaxFee.gt(ethers.utils.parseUnits(MAX_GAS_FEE_GWEI.toString(), "gwei"))
    ? ethers.utils.parseUnits(MAX_GAS_FEE_GWEI.toString(), "gwei")
    : calculatedMaxFee;

  // Use this for deployment transactions
  const overrides = {
    maxFeePerGas: maxFeePerGas,
    maxPriorityFeePerGas: adjustedPriorityFee,
    gasLimit: 5000000,  // Adjust this value based on your contract's complexity
  };

  console.log("Base fee:", ethers.utils.formatUnits(baseFee, "gwei"), "Gwei");
  console.log("Max fee per gas:", ethers.utils.formatUnits(maxFeePerGas, "gwei"), "Gwei");
  console.log("Priority fee:", ethers.utils.formatUnits(adjustedPriorityFee, "gwei"), "Gwei");

  console.log("--------------- Contract Deployment Started ---------------");

  const PriceOracle = await ethers.getContractFactory("PriceOracle");
  const priceOracle = await PriceOracle.deploy(addresses.WETH_Address);

  console.log("priceOracle address:", priceOracle.address);

  await priceOracle.setFeeds(
    ["0x2170Ed0880ac9A755fd29B2688956BD959F933F8"],
    [
    "0x0000000000000000000000000000000000000348"
    ],
    [
    "0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e"
    ],
  );

  // await tenderly.verify({
  //   name: "PriceOracle",
  //   address: priceOracle.address,
  // });

  const EnsoHandler = await ethers.getContractFactory("EnsoHandler");
  const ensoHandler = await EnsoHandler.deploy();

  console.log("ensoHandler address:", ensoHandler.address);

  // await tenderly.verify({
  //   name: "EnsoHandler",
  //   address: ensoHandler.address,
  // });

  const TokenBalanceLibrary = await ethers.getContractFactory(
    "TokenBalanceLibrary"
  );

  const tokenBalanceLibrary = await TokenBalanceLibrary.deploy();
  await tokenBalanceLibrary.deployed();

  console.log("tokenBalanceLibrary address:", tokenBalanceLibrary.address);

  // await tenderly.verify({
  //   name: "TokenBalanceLibrary",
  //   address: tokenBalanceLibrary.address,
  // });

  const VenusAssetHandler = await ethers.getContractFactory(
    "VenusAssetHandler"
  );
  const venusAssetHandler = await VenusAssetHandler.deploy();
  await venusAssetHandler.deployed();

  console.log("venusAssetHandler address:", venusAssetHandler.address);

  // await tenderly.verify({
  //   name: "VenusAssetHandler",
  //   address: venusAssetHandler.address,
  // });

  const PositionWrapper = await ethers.getContractFactory(
    "PositionWrapper"
  );
  const positionWrapperBaseAddress = await PositionWrapper.deploy();
  await positionWrapperBaseAddress.deployed(overrides);

  console.log("positionWrapperBaseAddress address:", positionWrapperBaseAddress.address);

  // await tenderly.verify({
  //   name: "PositionWrapper",
  //   address: positionWrapperBaseAddress.address,
  // });

  const PositionManager = await ethers.getContractFactory(
    "PositionManagerThena"
  );
  const positionManagerBaseAddress = await PositionManager.deploy();
  await positionManagerBaseAddress.deployed(overrides);

  console.log("positionManagerBaseAddress address:", positionManagerBaseAddress.address);

  // await tenderly.verify({
  //   name: "PositionManagerThena",
  //   address: positionManagerBaseAddress.address,
  // });

  const AmountCalculationsAlgebra = await ethers.getContractFactory(
    "AmountCalculationsAlgebra"
  );
  const amountCalculationsAlgebra = await AmountCalculationsAlgebra.deploy();
  await amountCalculationsAlgebra.deployed(overrides);

  console.log("amountCalculationsAlgebra address:", amountCalculationsAlgebra.address);

  // await tenderly.verify({
  //   name: "AmountCalculationsAlgebra",
  //   address: amountCalculationsAlgebra.address,
  // });

  const ProtocolConfig = await ethers.getContractFactory("ProtocolConfig");
  const protocolConfig = ProtocolConfig.attach("0xA0dAA6182D526F9c76629B2E66D2bDA8058c0FF3");
  const protocolConfig = await upgrades.deployProxy(ProtocolConfig, [
    treasury.address,
    priceOracle.address,
    positionWrapperBaseAddress.address,
  ],{kind : "uups"});

  // await tenderly.verify({
  //   name: "ProtocolConfig",
  //   address: protocolConfig.address,
  // });

  await protocolConfig.enableTokens([
    "0x2170Ed0880ac9A755fd29B2688956BD959F933F8"
  ]);

  await protocolConfig.updateProtocolFee(0);
  await protocolConfig.updateProtocolStreamingFee(0);

  console.log("protocolConfig address:", protocolConfig.address);

  await protocolConfig.setCoolDownPeriod("60");

  await protocolConfig.enableSolverHandler("0x1c25AEB86e0f2Be63B6Ffd33C0Bb8fabcDa903f3");

  await protocolConfig.setAssetHandlers(
    [
      addresses.vBNB_Address,
      addresses.vBTC_Address,
      addresses.vDAI_Address,
      addresses.vUSDT_Address,
      addresses.vUSDT_DeFi_Address,
      addresses.corePool_controller,
    ],
    [
      "0xCFc13b0AAF287152ceE5B3e6f99d6D0332e42c0c",
      "0xCFc13b0AAF287152ceE5B3e6f99d6D0332e42c0c",
      "0xCFc13b0AAF287152ceE5B3e6f99d6D0332e42c0c",
      "0xCFc13b0AAF287152ceE5B3e6f99d6D0332e42c0c",
      "0xCFc13b0AAF287152ceE5B3e6f99d6D0332e42c0c",
      "0xCFc13b0AAF287152ceE5B3e6f99d6D0332e42c0c",
    ]
  );

  await protocolConfig.setSupportedControllers([
    addresses.corePool_controller,
  ]);

  await protocolConfig.setSupportedFactory(addresses.thena_factory);

  await protocolConfig.setAssetAndMarketControllers(
    [
      addresses.vBNB_Address,
      addresses.vBTC_Address,
      addresses.vDAI_Address,
      addresses.vUSDT_Address
    ],
    [
      addresses.corePool_controller,
      addresses.corePool_controller,
      addresses.corePool_controller,
      addresses.corePool_controller
    ]
  );

  console.log("-----------------------------------------------")

  const Rebalancing = await ethers.getContractFactory("Rebalancing", {
    libraries: {
      TokenBalanceLibrary: "0x71611CbFa3FFdf75BDE22761915c68FAd7a1772B",
    },
  });
  const rebalancingDefault = await Rebalancing.deploy(overrides);

  console.log("rebalancingDefult address:", rebalancingDefault.address);

  await tenderly.verify({
    name: "Rebalancing",
    address: rebalancingDefault.address,
  });

  const AssetManagementConfig = await ethers.getContractFactory(
    "AssetManagementConfig",
  );
  const assetManagementConfig = await AssetManagementConfig.deploy(overrides);

  console.log("assetManagerConfig address:", assetManagementConfig.address);

  await tenderly.verify({
    name: "AssetManagementConfig",
    address: assetManagementConfig.address,
  });

  const Portfolio = await ethers.getContractFactory("Portfolio", {
    libraries: {
      TokenBalanceLibrary: "0x71611CbFa3FFdf75BDE22761915c68FAd7a1772B",
    },
  });
  const portfolioContract = await Portfolio.deploy(overrides);

  console.log("portfolioContract address:", portfolioContract.address);

  await tenderly.verify({
    name: "Portfolio",
    address: portfolioContract.address,
  });

  const FeeModule = await ethers.getContractFactory("FeeModule");
  const feeModule = await FeeModule.deploy(overrides);

  console.log("feeModule address:", feeModule.address);

  await tenderly.verify({
    name: "FeeModule",
    address: feeModule.address,
  });

  const VelvetSafeModule = await ethers.getContractFactory("VelvetSafeModule");
  const velvetSafeModule = await VelvetSafeModule.deploy(overrides);

  console.log("velvetSafeModule address:", velvetSafeModule.address);

  await tenderly.verify({
    name: "VelvetSafeModule",
    address: velvetSafeModule.address,
  });

  const TokenExclusionManager = await ethers.getContractFactory(
    "TokenExclusionManager",
  );
  const tokenExclusionManager = await TokenExclusionManager.deploy(overrides);

  console.log("tokenExclusionManager address:", tokenExclusionManager.address);

  // await tenderly.verify({
  //   name: "TokenExclusionManager",
  //   address: tokenExclusionManager.address,
  // });

  const TokenRemovalVault = await ethers.getContractFactory(
    "TokenRemovalVault",
  );
  const tokenRemovalVault = await TokenRemovalVault.deploy(overrides);
  await tokenRemovalVault.deployed();

  console.log("tokenRemovalVault address:", tokenRemovalVault.address);

  // await tenderly.verify({
  //   name: "TokenRemovalVault",
  //   address: tokenRemovalVault.address,
  // });

  const DepositBatch = await ethers.getContractFactory("DepositBatchExternalPositions");
  const depositBatch = await DepositBatch.deploy(overrides);

  console.log("depositBatch address:", depositBatch.address);

  // await tenderly.verify({
  //   name: "DepositBatchExternalPositions",
  //   address: depositBatch.address,
  // });

  const DepositManager = await ethers.getContractFactory("DepositManagerExternalPositions");
  const depositManager = await DepositManager.deploy(depositBatch.address,overrides);

  console.log("depositManager address:", depositManager.address);

  // await tenderly.verify({
  //   name: "DepositManagerExternalPositions",
  //   address: depositManager.address,
  // });

  const WithdrawBatch = await ethers.getContractFactory("WithdrawBatchExternalPositions");
  const withdrawBatch = await WithdrawBatch.deploy(overrides);

  console.log("withdrawBatch address:", withdrawBatch.address);

  // await tenderly.verify({
  //   name: "WithdrawBatchExternalPositions",
  //   address: withdrawBatch.address,
  // });

  const PortfolioCalculations = await ethers.getContractFactory(
    "PortfolioCalculations",
    {
      libraries: {
        TokenBalanceLibrary: "0x71611CbFa3FFdf75BDE22761915c68FAd7a1772B",
      },
    }
  );
  const portfolioCalculations = await PortfolioCalculations.deploy(overrides);

  console.log("portfolioCalculations address:", portfolioCalculations.address);

  // await tenderly.verify({
  //   name: "PortfolioCalculations",
  //   address: portfolioCalculations.address,
  // });

  const BorrowManager = await ethers.getContractFactory("BorrowManager");
  const borrowManager = await BorrowManager.deploy(overrides);
  await borrowManager.deployed();

  console.log("borrowManager address:", borrowManager.address);

  // await tenderly.verify({
  //   name: "BorrowManager",
  //   address: borrowManager.address,
  // });

  console.log(
    "------------------------------ Deployment Ended ------------------------------",
  );

  const PortfolioFactory = await ethers.getContractFactory("PortfolioFactory");

  const portfolioFactoryInstance = await upgrades.deployProxy(
    PortfolioFactory,
    [
      {
        _basePortfolioAddress: "0xe22e87D20b8bB974D77cEC144e211A48F1724B75",
        _baseTokenExclusionManagerAddress: tokenExclusionManager.address,
        _baseRebalancingAddres: "0x608Ed5B2E72cAc3d30Fae5747a6d46Bd405fb1B0",
        _baseAssetManagementConfigAddress: "0x22d44ec3f1F217c97CcF3CA1B500043a66101082",
        _feeModuleImplementationAddress: "0x2f3eDbFf040DeB8357262D93078D6B6C8B4C5Fb8",
        _baseTokenRemovalVaultImplementation: tokenRemovalVault.address,
        _baseVelvetGnosisSafeModuleAddress: "0xaDf04f22a0b5548A5124cF692B8C5e6d19c8a0e5",
        _baseBorrowManager: borrowManager.address,
        _basePositionManager: "0x1E856CA28cd33876D6E40a7c7bd202d362bba217",
        _gnosisSingleton: addresses.gnosisSingleton,
        _gnosisFallbackLibrary: addresses.gnosisFallbackLibrary,
        _gnosisMultisendLibrary: addresses.gnosisMultisendLibrary,
        _gnosisSafeProxyFactory: addresses.gnosisSafeProxyFactory,
        _protocolConfig: "0xA0dAA6182D526F9c76629B2E66D2bDA8058c0FF3",
      },
    ],
    { kind: "uups",...overrides },
  );

  const portfolioFactory = PortfolioFactory.attach(
    portfolioFactoryInstance.address,
  );

  console.log("portfolioFactory address:", portfolioFactory.address);

  const WithdrawManager = await ethers.getContractFactory("WithdrawManager");
  const withdrawManager = await WithdrawManager.deploy(overrides);

  console.log("withdrawManager address:", withdrawManager.address);

  // await tenderly.verify({
  //   name: "WithdrawManagerExternalPositions",
  //   address: withdrawManager.address,
  // });

  await withdrawManager.initialize(
    withdrawBatch.address,
    portfolioFactory.address,
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
