const { ethers, upgrades, tenderly } = require("hardhat");
const { chainIdToAddresses } = require("../scripts/networkVariables");
import { tokenAddresses, priceOracle } from "../test/Bsc/Deployments.test";
import { BigNumber, Contract } from "ethers";

import {
    createEnsoCallData,
  createEnsoCallDataRoute,
  calculateOutputAmounts,
  calculateDepositAmounts,
  } from "../test/Bsc/IntentCalculations";

async function main() {
    let owner;
  let treasury;
  let accounts = await ethers.getSigners();
  [owner, treasury] = accounts;

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

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  const MIN_TICK = -887220;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  const MAX_TICK = 887220;

  const chainId: any = process.env.CHAIN_ID;
  const addresses = chainIdToAddresses[chainId];

  console.log("--------------- Contract TEST Started ---------------");

  const PortfolioFactory = await ethers.getContractFactory("PortfolioFactory");

  const portfolioFactory = PortfolioFactory.attach(
    "0xe19Ef21Fe25cE26E035Bc32E4a434D4e23B34087"
  );

  const PositionManager = await ethers.getContractFactory(
    "PositionManagerThena"
  );

//   const positionManager = PositionManager.attach("0x1E856CA28cd33876D6E40a7c7bd202d362bba217");

    // const portfolioFactoryCreate =
    //   await portfolioFactory.createPortfolioNonCustodial({
    //     _name: "PORTFOLIOLY",
    //     _symbol: "IDX",
    //     _managementFee: "20",
    //     _performanceFee: "2500",
    //     _entryFee: "0",
    //     _exitFee: "0",
    //     _initialPortfolioAmount: "1000000000000000000",
    //     _minPortfolioTokenHoldingAmount: "10000000000000000",
    //     _assetManagerTreasury: treasury.address,
    //     _whitelistedTokens: [],
    //     _public: true,
    //     _transferable: true,
    //     _transferableToPublic: true,
    //     _whitelistTokens: false,
    //     _externalPositionManagementWhitelisted: true,
    //   });

      console.log("--------------- PORTFOLIO DEPLOYED ---------------");

      const portfolioAddress = await portfolioFactory.getPortfolioList(1);
    
      console.log("portfolioAddress", portfolioAddress);
    
      const portfolioInfo = await portfolioFactory.PortfolioInfolList(1);
    
      const Portfolio = await ethers.getContractFactory("Portfolio", {
        libraries: {
          TokenBalanceLibrary: "0x71611CbFa3FFdf75BDE22761915c68FAd7a1772B",
        },
      });
    
      const portfolio = Portfolio.attach(portfolioAddress);
    
      const Rebalancing = await ethers.getContractFactory("Rebalancing", {
        libraries: {
          TokenBalanceLibrary: "0x71611CbFa3FFdf75BDE22761915c68FAd7a1772B",
        },
      });
    
      const rebalancing = Rebalancing.attach(portfolioInfo.rebalancing);
    
      console.log("Rebalancing address", portfolioInfo.rebalancing);

      const AssetManagementConfig = await ethers.getContractFactory(
        "AssetManagementConfig",
      );
      const config = await portfolio.assetManagementConfig();
      console.log("config",config);
      const assetManagementConfig = AssetManagementConfig.attach(config);

    //   await assetManagementConfig.enableUniSwapV3Manager(overrides);

      console.log("Enable DONE");

      let positionManagerAddress =
        await assetManagementConfig.positionManager();

      const positionManager = PositionManager.attach(positionManagerAddress);

      console.log("positionManagerAddress",positionManager.address);

      console.log("--------------- CREATE POSITION ---------------");

    //   const token0 = addresses.ETH_Address;
    //   const token1 = addresses.BTC_Address;

        // await positionManager.createNewWrapperPosition(
        //   token0,
        //   token1,
        //   "Test",
        //   "t",
        //   MIN_TICK,
        //   MAX_TICK
        // );

        // console.log("position deployed");

        let position1 = await positionManager.deployedPositionWrappers(0);

        console.log("position1",position1);

        const PositionWrapper = await ethers.getContractFactory(
          "PositionWrapper"
        );
        let positionWrapper = PositionWrapper.attach(position1);

    console.log("--------------- CREATE POSITION 2---------------");

    // const token0 = addresses.BTC_Address;
    //     const token1 = addresses.ETH_Address;

        // await positionManager.createNewWrapperPosition(
        //   token0,
        //   token1,
        //   "Test",
        //   "t",
        //   MIN_TICK,
        //   MAX_TICK
        // );

        const position2 = await positionManager.deployedPositionWrappers(1);

        console.log("position2",position2);

        let positionWrapper2 = PositionWrapper.attach(position2);

    console.log("--------------- INIT TOKENS ---------------");

    // await portfolio.initToken([
    //     addresses.USDC_Address,
    //     position2,
    //     addresses.DOGE_Address,
    //     addresses.BTC_Address,
    //     position1,
    //   ]);

      console.log("done init");

      let positionWrappers = [position2, position1];
      let swapTokens = [
        addresses.USDC_Address,
        await positionWrapper2.token0(), // position2 - token0
        await positionWrapper2.token1(), // position2 - token1
        addresses.DOGE_Address,
        addresses.BTC_Address,
        await positionWrapper.token0(), // position1 - token0
        await positionWrapper.token1(), // position1 - token1
      ];
      let positionWrapperIndex = [1, 4];
      let portfolioTokenIndex = [0, 1, 1, 2, 3, 4, 4];
      let isExternalPosition = [false, true, true, false, false, true, true];
      let isTokenExternalPosition = [false, true, false, false, true];
      let index0 = [1, 5];
      let index1 = [2, 6];

      console.log("-----------------1st Investment--------------------------")

      let tokens = await portfolio.getTokens();

      const DepositBatch = await ethers.getContractFactory("DepositBatchExternalPositions");
      const depositBatch = DepositBatch.attach(
       "0x145efd0Cc8151d7984E4f032FDFe376A746d20eC"
      );

      console.log("SupplyBefore", await portfolio.totalSupply());

    //     let postResponse = [];

    //     for (let i = 0; i < swapTokens.length; i++) {
    //       let response = await createEnsoCallDataRoute(
    //         depositBatch.address,
    //         depositBatch.address,
    //         "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    //         swapTokens[i],
    //         "2428571428571428"
    //       );
    //       postResponse.push(response.data.tx.data);
    //     }

    //     console.log("calldata done");

    //     const data = await depositBatch.multiTokenSwapETHAndTransfer(
    //       {
    //         _minMintAmount: 0,
    //         _depositAmount: "17000000000000000",
    //         _target: portfolio.address,
    //         _depositToken: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    //         _callData: postResponse,
    //       },
    //       {
    //         _positionWrappers: positionWrappers,
    //         _swapTokens: swapTokens,
    //         _positionWrapperIndex: positionWrapperIndex,
    //         _portfolioTokenIndex: portfolioTokenIndex,
    //         _index0: index0,
    //         _index1: index1,
    //         _amount0Min: 1,
    //         _amount1Min: 1,
    //         _isExternalPosition: isExternalPosition,
    //         _tokenIn: ZERO_ADDRESS,
    //         _tokenOut: ZERO_ADDRESS,
    //         _amountIn: "0",
    //       },
    //       {
    //         value: "17000000000000000",
    //       }
    //     );

    console.log("------should rebalance to lending token----")

    const EnsoHandler = await ethers.getContractFactory("EnsoHandler");
  const ensoHandler = EnsoHandler.attach(
    "0x1c25AEB86e0f2Be63B6Ffd33C0Bb8fabcDa903f3"
  );

    // let sellToken = tokens[3];
    //     let buyToken = addresses.vBNB_Address;

    //     let newTokens = [tokens[0], tokens[1], tokens[2],buyToken,tokens[4]];

    //     let vault = await portfolio.vault();

    //     let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
    //     let balance = BigNumber.from(
    //       await ERC20.attach(sellToken).balanceOf(vault)
    //     ).toString();

    //     let balanceToSwap = BigNumber.from(balance).toString();
    //     console.log("Balance to rebalance", balanceToSwap);

    //     const postResponse = await createEnsoCallDataRoute(
    //       ensoHandler.address,
    //       ensoHandler.address,
    //       sellToken,
    //       buyToken,
    //       balanceToSwap
    //     );

    //     const encodedParameters = ethers.utils.defaultAbiCoder.encode(
    //       [
    //         "bytes[][]", // callDataEnso
    //         "bytes[]", // callDataDecreaseLiquidity
    //         "bytes[][]", // callDataIncreaseLiquidity
    //         "address[][]", // increaseLiquidityTarget
    //         "address[]", // underlyingTokensDecreaseLiquidity
    //         "address[]", // tokensIn
    //         "address[]", // tokens
    //         "uint256[]", // minExpectedOutputAmounts
    //       ],
    //       [
    //         [[postResponse.data.tx.data]],
    //         [],
    //         [[]],
    //         [[]],
    //         [],
    //         [sellToken],
    //         [buyToken],
    //         [0],
    //       ]
    //     );

    //     await rebalancing.updateTokens({
    //       _newTokens: newTokens,
    //       _sellTokens: [sellToken],
    //       _sellAmounts: [balanceToSwap],
    //       _handler: ensoHandler.address,
    //       _callData: encodedParameters,
    //     });

    console.log("---------Borrow USDT using vBNB as collateral----------")

    let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
    let vault = await portfolio.vault();
    console.log(
      "USDT Balance before",
        await ERC20.attach(addresses.USDT).balanceOf(vault)
    );

        // await rebalancing.borrow(
        //   addresses.vUSDT_Address,
        //   [addresses.vBNB_Address],
        //   addresses.USDT,
        //   addresses.corePool_controller,
        //   "1200000000000000000",
        //   overrides
        // );
    console.log("----------POSITION 3----------------")
    // UniswapV3 position
    // const token0 = addresses.USDC_Address;
    // const token1 = addresses.USDT;

    // await positionManager.createNewWrapperPosition(
    //   token0,
    //   token1,
    //   "Test",
    //   "t",
    //   MIN_TICK,
    //   MAX_TICK
    // );

    let position3 = await positionManager.deployedPositionWrappers(2);

    console.log("position3",position3);

    let positionWrapper3 = PositionWrapper.attach(position3);

    console.log("----------rebalancing borrowed USDT to mint a new position---------")
    
    // let sellToken = addresses.USDT;
    //     let buyToken = position3;

    //     let addedPosition = positionWrapper3;

    //     let token0 = await addedPosition.token0();
    //     let token1 = await addedPosition.token1();

    //     let newTokens = [
    //       tokens[0],
    //       tokens[1], // position1
    //       tokens[2],
    //       tokens[3],//position2
    //       tokens[4],
    //       buyToken
    //     ];

    //     positionWrappers = [position1, position2, buyToken];
    //     swapTokens = [
    //       addresses.USDC_Address,
    //       await positionWrapper2.token0(), // position2 - token0
    //       await positionWrapper2.token1(), // position2 - token1
    //       addresses.DOGE_Address,
    //       addresses.vBNB_Address,
    //       await positionWrapper.token0(), // position1 - token0
    //       await positionWrapper.token1(), // position1 - token1
    //       token0,
    //       token1
    //     ];
    //     positionWrapperIndex = [1, 4, 5];
    //     portfolioTokenIndex = [0, 1, 1, 2, 3, 4, 4, 5, 5];
    //     isExternalPosition = [false, true, true, false, false, true, true, true, true];
    //     isTokenExternalPosition = [false, true, false, false, true, true];
    //     index0 = [1, 5, 7];
    //     index1 = [2, 6, 8];

    //     // let vault = await portfolio.vault();

    //     // let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
    //     let sellTokenBalance = BigNumber.from(
    //       await ERC20.attach(sellToken).balanceOf(vault)
    //     ).toString();

    //     let depositAmounts = await calculateDepositAmounts(
    //       buyToken,
    //       MIN_TICK,
    //       MAX_TICK,
    //       sellTokenBalance
    //     );

    //     let callDataEnso: any = [[]];
    //     if (sellToken != token0) {
    //       let swapAmount = depositAmounts.amount0;
    //       const postResponse0 = await createEnsoCallDataRoute(
    //         ensoHandler.address,
    //         ensoHandler.address,
    //         sellToken,
    //         token0,
    //         swapAmount
    //       );
    //       callDataEnso[0].push(postResponse0.data.tx.data);
    //     }

    //     if (sellToken != token1) {
    //       let swapAmount = depositAmounts.amount1;

    //       const postResponse1 = await createEnsoCallDataRoute(
    //         ensoHandler.address,
    //         ensoHandler.address,
    //         sellToken,
    //         token1,
    //         swapAmount
    //       );
    //       callDataEnso[0].push(postResponse1.data.tx.data);
    //     }

    //     const callDataIncreaseLiquidity: any = [[]];
    //     // Encode the function call
    //     let ABIApprove = ["function approve(address spender, uint256 amount)"];
    //     let abiEncodeApprove = new ethers.utils.Interface(ABIApprove);
    //     callDataIncreaseLiquidity[0][0] = abiEncodeApprove.encodeFunctionData(
    //       "approve",
    //       [positionManager.address, sellTokenBalance]
    //     );

    //     callDataIncreaseLiquidity[0][1] = abiEncodeApprove.encodeFunctionData(
    //       "approve",
    //       [positionManager.address, sellTokenBalance]
    //     );

    //     // Define the ABI with the correct structure of WrapperDepositParams
    //     let ABI = [
    //       "function initializePositionAndDeposit(address _dustReceiver, address _positionWrapper, (uint256 _amount0Desired, uint256 _amount1Desired, uint256 _amount0Min, uint256 _amount1Min) params)",
    //     ];

    //     let abiEncode = new ethers.utils.Interface(ABI);

    //     // Encode the initializePositionAndDeposit function call
    //     callDataIncreaseLiquidity[0][2] = abiEncode.encodeFunctionData(
    //       "initializePositionAndDeposit",
    //       [
    //         owner.address, // _dustReceiver
    //         buyToken, // _positionWrapper
    //         {
    //           _amount0Desired: (depositAmounts.amount0 * 0.9995).toFixed(0),
    //           _amount1Desired: (depositAmounts.amount1 * 0.9995).toFixed(0),
    //           _amount0Min: 0,
    //           _amount1Min: 0,
    //         },
    //       ]
    //     );

    //     const encodedParameters = ethers.utils.defaultAbiCoder.encode(
    //       [
    //         " bytes[][]", // callDataEnso
    //         "bytes[]", // callDataDecreaseLiquidity
    //         "bytes[][]", // callDataIncreaseLiquidity
    //         "address[][]", // increaseLiquidityTarget
    //         "address[]", // underlyingTokensDecreaseLiquidity
    //         "address[]", // tokensIn
    //         "address[]", // tokens
    //         " uint256[]", // minExpectedOutputAmounts
    //       ],
    //       [
    //         callDataEnso,
    //         [],
    //         callDataIncreaseLiquidity,
    //         [[token0, token1, positionManager.address]],
    //         [],
    //         [sellToken],
    //         [buyToken],
    //         [0],
    //       ]
    //     );

    //     await rebalancing.updateTokens({
    //       _newTokens: newTokens,
    //       _sellTokens: [sellToken],
    //       _sellAmounts: [sellTokenBalance],
    //       _handler: ensoHandler.address,
    //       _callData: encodedParameters,
    //     });

    console.log("--------Repay borrowed USDT-------------")

    const PortfolioCalculations = await ethers.getContractFactory(
    "PortfolioCalculations",
    {
      libraries: {
        TokenBalanceLibrary: "0x71611CbFa3FFdf75BDE22761915c68FAd7a1772B",
      },
    }
  );

const portfolioCalculations = PortfolioCalculations.attach(
    "0x99e8bE610D5E90291810c41E235717C1FeD1e288"
  );

  const VenusAssetHandler = await ethers.getContractFactory(
    "VenusAssetHandler"
  );

    const venusAssetHandler = VenusAssetHandler.attach("0xCFc13b0AAF287152ceE5B3e6f99d6D0332e42c0c");

    let flashloanBufferUnit = 16;//Flashloan buffer unit in 1/10000
        let bufferUnit = 130;//Buffer unit for collateral amount in 1/100000

        let balanceBorrowed =
          await portfolioCalculations.getVenusTokenBorrowedBalance(
            [addresses.vUSDT_Address],
            vault
          );
        const userData = await venusAssetHandler.getUserAccountData(
          vault,
          addresses.corePool_controller
        );
        const lendTokens = userData[1].lendTokens;

        console.log("balanceBorrowed before repay", balanceBorrowed);

        const balanceToRepay = "1200030600588321624";

        // const balanceToSwap = (await portfolioCalculations.calculateFlashLoanAmountForRepayment(
        //   addresses.vDAI_Address,
        //   addresses.vUSDT_Address,
        //   addresses.corePool_controller,
        //   balanceToRepay,
        //   flashloanBufferUnit
        // )).toString();

        const balanceToSwap = BigNumber.from(balanceToRepay).add(BigNumber.from(balanceToRepay).div("1000"));

        console.log("balanceToRepay", balanceToRepay);
        console.log("balanceToSwap", balanceToSwap);

        // const postResponse = await createEnsoCallDataRoute(
        //   ensoHandler.address,
        //   ensoHandler.address,
        //   addresses.USDT,
        //   addresses.DAI_Address,
        //   balanceToSwap
        // );

        const encodedParameters = ethers.utils.defaultAbiCoder.encode(
          ["bytes[]", "address[]", "uint256[]"],
          [["0x"], [addresses.DAI_Address], [0]]
        );

        let encodedParameters1 = [];
        //Because repay(rebalance) is one borrow token at a time
        const amounToSell =
          await portfolioCalculations.getCollateralAmountToSell(
            vault,
            addresses.corePool_controller,
            venusAssetHandler.address,
            addresses.vUSDT_Address,
            balanceToSwap,
            "10", //Flash loan fee
            bufferUnit //Buffer unit for collateral amount
          );
        console.log("amounToSell", amounToSell);
        console.log("lendTokens", lendTokens);

        for (let j = 0; j < lendTokens.length; j++) {
          const postResponse1 = await createEnsoCallDataRoute(
            ensoHandler.address,
            ensoHandler.address,
            lendTokens[j],
            addresses.USDT,
            amounToSell[j].toString() //Need calculation here
          );

          encodedParameters1.push(
            ethers.utils.defaultAbiCoder.encode(
              ["bytes[]", "address[]", "uint256[]"],
              [[postResponse1.data.tx.data], [addresses.USDT], [0]]
            )
          );
        }

        await rebalancing.repay(addresses.corePool_controller, {
          _factory: addresses.thena_factory,
          _token0: addresses.USDT, //USDT - Pool token
          _token1: addresses.USDC_Address, //USDC - Pool token
          _flashLoanToken: addresses.USDT, //Token to take flashlaon
          _debtToken: [addresses.USDT], //Token to pay debt of
          _protocolToken: [addresses.vUSDT_Address], // lending token in case of venus
          _bufferUnit: bufferUnit, //Buffer unit for collateral amount
          _solverHandler: ensoHandler.address, //Handler to swap
          _flashLoanAmount: [balanceToSwap],
          _debtRepayAmount: [balanceToRepay],
          firstSwapData: [encodedParameters],
          secondSwapData: encodedParameters1,
          isMaxRepayment: true
        });

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
