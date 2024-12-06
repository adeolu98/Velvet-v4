import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import "@nomicfoundation/hardhat-chai-matchers";
import { ethers, upgrades } from "hardhat";
import { BigNumber, Contract } from "ethers";
import {
  PERMIT2_ADDRESS,
  AllowanceTransfer,
  MaxAllowanceTransferAmount,
  PermitBatch,
} from "@uniswap/permit2-sdk";

import {
  calcuateExpectedMintAmount,
  createEnsoDataElement,
} from "../calculations/DepositCalculations.test";

import {
  createEnsoCallData,
  createEnsoCallDataRoute,
  createMetaAggregatorCalldata,
  calculateOutputAmounts,
} from "./IntentCalculations";

import { priceOracle } from "./Deployments.test";

import {
  Portfolio,
  Portfolio__factory,
  ProtocolConfig,
  Rebalancing__factory,
  PortfolioFactory,
  EnsoHandler,
  VelvetSafeModule,
  FeeModule,
  UniswapV2Handler,
  TokenBalanceLibrary,
  BorrowManager,
  TokenExclusionManager,
  MetaAggregatorHandler,
  TokenExclusionManager__factory,
  DepositBatchExternalPositionsMeta,
  DepositManagerExternalPositionsMeta,
  WithdrawBatchExternalPositionsMeta,
  WithdrawManagerExternalPositionsMeta,
  PositionManagerUniswap,
} from "../../typechain";

import { chainIdToAddresses } from "../../scripts/networkVariables";

var chai = require("chai");
const axios = require("axios");
const qs = require("qs");
//use default BigNumber
chai.use(require("chai-bignumber")());

describe.only("Tests for Deposit + Withdrawal", () => {
  let accounts;
  let vaultAddress: string;
  let velvetSafeModule: VelvetSafeModule;
  let portfolio: any;
  let portfolio1: any;
  let portfolio2: any;
  let portfolioCalculations: any;
  let tokenExclusionManager: any;
  let tokenExclusionManager1: any;
  let tokenExclusionManager2: any;
  let ensoHandler: EnsoHandler;
  let metaAggregatorHandler: MetaAggregatorHandler;
  let portfolioContract: Portfolio;
  let portfolioFactory: PortfolioFactory;
  let swapHandler: UniswapV2Handler;
  let rebalancing: any;
  let rebalancing1: any;
  let rebalancing2: any;
  let protocolConfig: ProtocolConfig;
  let borrowManager: BorrowManager;
  let tokenBalanceLibrary: TokenBalanceLibrary;
  let txObject;
  let owner: SignerWithAddress;
  let treasury: SignerWithAddress;
  let assetManagerTreasury: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let depositor1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addrs: SignerWithAddress[];
  let feeModule0: FeeModule;
  let zeroAddress: any;
  let approve_amount = ethers.constants.MaxUint256; //(2^256 - 1 )
  let token;
  let depositBatch: DepositBatchExternalPositionsMeta;
  let depositManager: DepositManagerExternalPositionsMeta;
  let withdrawBatch: WithdrawBatchExternalPositionsMeta;
  let withdrawManager: WithdrawManagerExternalPositionsMeta;
  let positionManager: PositionManagerUniswap;

  let positionWrapper: any;

  let positionWrappers: any = [];
  let swapTokens: any = [];
  let positionWrapperIndex: any = [];
  let portfolioTokenIndex: any = [];
  let isExternalPosition: any = [];
  let index0: any = [];
  let index1: any = [];

  let position1: any;
  let position2: any;

  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  const MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  const MAX_TICK = -MIN_TICK;

  const provider = ethers.provider;
  const chainId: any = process.env.CHAIN_ID;
  const addresses = chainIdToAddresses[chainId];

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  function delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
  describe.only("Tests for Deposit + Withdrawal", () => {
    before(async () => {
      accounts = await ethers.getSigners();
      [
        owner,
        depositor1,
        nonOwner,
        treasury,
        assetManagerTreasury,
        addr1,
        addr2,
        ...addrs
      ] = accounts;

      const provider = ethers.getDefaultProvider();

      const TokenBalanceLibrary = await ethers.getContractFactory(
        "TokenBalanceLibrary"
      );

      tokenBalanceLibrary = await TokenBalanceLibrary.deploy();
      await tokenBalanceLibrary.deployed();

      const EnsoHandler = await ethers.getContractFactory("EnsoHandler");
      ensoHandler = await EnsoHandler.deploy();
      await ensoHandler.deployed();

      const MetaAggregatorHandler = await ethers.getContractFactory(
        "MetaAggregatorHandler"
      );
      metaAggregatorHandler = await MetaAggregatorHandler.deploy();
      await metaAggregatorHandler.deployed();

      const DepositBatch = await ethers.getContractFactory(
        "DepositBatchExternalPositionsMeta"
      );
      depositBatch = await DepositBatch.deploy();
      await depositBatch.deployed();

      const DepositManager = await ethers.getContractFactory(
        "DepositManagerExternalPositionsMeta"
      );
      depositManager = await DepositManager.deploy(depositBatch.address);
      await depositManager.deployed();

      const WithdrawBatch = await ethers.getContractFactory(
        "WithdrawBatchExternalPositionsMeta"
      );
      withdrawBatch = await WithdrawBatch.deploy();
      await withdrawBatch.deployed();

      const WithdrawManager = await ethers.getContractFactory(
        "WithdrawManagerExternalPositionsMeta"
      );
      withdrawManager = await WithdrawManager.deploy();
      await withdrawManager.deployed();

      const PositionWrapper = await ethers.getContractFactory(
        "PositionWrapper"
      );
      const positionWrapperBaseAddress = await PositionWrapper.deploy();
      await positionWrapperBaseAddress.deployed();

      const ProtocolConfig = await ethers.getContractFactory("ProtocolConfig");
      const _protocolConfig = await upgrades.deployProxy(
        ProtocolConfig,
        [
          treasury.address,
          priceOracle.address,
          positionWrapperBaseAddress.address,
        ],
        { kind: "uups" }
      );

      protocolConfig = ProtocolConfig.attach(_protocolConfig.address);
      await protocolConfig.setCoolDownPeriod("70");
      await protocolConfig.enableSolverHandler(ensoHandler.address);
      await protocolConfig.enableSolverHandler(metaAggregatorHandler.address);

      await protocolConfig.enableTokens([addresses.USDC, addresses.DAI]);

      const Rebalancing = await ethers.getContractFactory("Rebalancing");
      const rebalancingDefult = await Rebalancing.deploy();
      await rebalancingDefult.deployed();

      const TokenExclusionManager = await ethers.getContractFactory(
        "TokenExclusionManager"
      );
      const tokenExclusionManagerDefault = await TokenExclusionManager.deploy();
      await tokenExclusionManagerDefault.deployed();

      const AssetManagementConfig = await ethers.getContractFactory(
        "AssetManagementConfig"
      );
      const assetManagementConfig = await AssetManagementConfig.deploy();
      await assetManagementConfig.deployed();

      const BorrowManager = await ethers.getContractFactory("BorrowManager");
      borrowManager = await BorrowManager.deploy();
      await borrowManager.deployed();

      const Portfolio = await ethers.getContractFactory("Portfolio", {
        libraries: {
          TokenBalanceLibrary: tokenBalanceLibrary.address,
        },
      });
      portfolioContract = await Portfolio.deploy();
      await portfolioContract.deployed();
      const PancakeSwapHandler = await ethers.getContractFactory(
        "UniswapV2Handler"
      );
      swapHandler = await PancakeSwapHandler.deploy();
      await swapHandler.deployed();

      swapHandler.init(addresses.SushiSwapRouterAddress);

      await protocolConfig.setSupportedFactory(ensoHandler.address);

      let whitelist = [owner.address];
      zeroAddress = "0x0000000000000000000000000000000000000000";

      const SwapVerificationLibrary = await ethers.getContractFactory(
        "SwapVerificationLibraryUniswap"
      );
      const swapVerificationLibrary = await SwapVerificationLibrary.deploy();
      await swapVerificationLibrary.deployed();

      const PositionManager = await ethers.getContractFactory(
        "PositionManagerUniswap",
        {
          libraries: {
            SwapVerificationLibraryUniswap: swapVerificationLibrary.address,
          },
        }
      );
      const positionManagerBaseAddress = await PositionManager.deploy();
      await positionManagerBaseAddress.deployed();

      const FeeModule = await ethers.getContractFactory("FeeModule");
      const feeModule = await FeeModule.deploy();
      await feeModule.deployed();

      const TokenRemovalVault = await ethers.getContractFactory(
        "TokenRemovalVault"
      );
      const tokenRemovalVault = await TokenRemovalVault.deploy();
      await tokenRemovalVault.deployed();

      const VelvetSafeModule = await ethers.getContractFactory(
        "VelvetSafeModule"
      );
      velvetSafeModule = await VelvetSafeModule.deploy();
      await velvetSafeModule.deployed();

      const PortfolioFactory = await ethers.getContractFactory(
        "PortfolioFactory"
      );

      const portfolioFactoryInstance = await upgrades.deployProxy(
        PortfolioFactory,
        [
          {
            _basePortfolioAddress: portfolioContract.address,
            _baseTokenExclusionManagerAddress:
              tokenExclusionManagerDefault.address,
            _baseRebalancingAddres: rebalancingDefult.address,
            _baseAssetManagementConfigAddress: assetManagementConfig.address,
            _feeModuleImplementationAddress: feeModule.address,
            _baseTokenRemovalVaultImplementation: tokenRemovalVault.address,
            _baseVelvetGnosisSafeModuleAddress: velvetSafeModule.address,
            _baseBorrowManager: borrowManager.address,
            _basePositionManager: positionManagerBaseAddress.address,
            _gnosisSingleton: addresses.gnosisSingleton,
            _gnosisFallbackLibrary: addresses.gnosisFallbackLibrary,
            _gnosisMultisendLibrary: addresses.gnosisMultisendLibrary,
            _gnosisSafeProxyFactory: addresses.gnosisSafeProxyFactory,
            _protocolConfig: protocolConfig.address,
          },
        ],
        { kind: "uups" }
      );

      portfolioFactory = PortfolioFactory.attach(
        portfolioFactoryInstance.address
      );

      await portfolioFactory.setPositionManagerAddresses(
        "0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1",
        "0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD"
      );

      await withdrawManager.initialize(
        withdrawBatch.address,
        portfolioFactory.address
      );

      console.log("portfolioFactory address:", portfolioFactory.address);
      const portfolioFactoryCreate =
        await portfolioFactory.createPortfolioNonCustodial({
          _name: "PORTFOLIOLY",
          _symbol: "IDX",
          _managementFee: "20",
          _performanceFee: "2500",
          _entryFee: "0",
          _exitFee: "0",
          _initialPortfolioAmount: "100000000000000000000",
          _minPortfolioTokenHoldingAmount: "10000000000000000",
          _assetManagerTreasury: assetManagerTreasury.address,
          _whitelistedTokens: [],
          _public: true,
          _transferable: true,
          _transferableToPublic: true,
          _whitelistTokens: false,
          _externalPositionManagementWhitelisted: true,
        });

      const portfolioAddress = await portfolioFactory.getPortfolioList(0);
      const portfolioInfo = await portfolioFactory.PortfolioInfolList(0);

      portfolio = await ethers.getContractAt(
        Portfolio__factory.abi,
        portfolioAddress
      );
      const PortfolioCalculations = await ethers.getContractFactory(
        "PortfolioCalculations",
        {
          libraries: {
            TokenBalanceLibrary: tokenBalanceLibrary.address,
          },
        }
      );
      feeModule0 = FeeModule.attach(await portfolio.feeModule());
      portfolioCalculations = await PortfolioCalculations.deploy();
      await portfolioCalculations.deployed();

      rebalancing = await ethers.getContractAt(
        Rebalancing__factory.abi,
        portfolioInfo.rebalancing
      );

      tokenExclusionManager = await ethers.getContractAt(
        TokenExclusionManager__factory.abi,
        portfolioInfo.tokenExclusionManager
      );

      const config = await portfolio.assetManagementConfig();
      const assetManagementConfig0 = AssetManagementConfig.attach(config);
      await assetManagementConfig0.enableUniSwapV3Manager();

      let positionManagerAddress =
        await assetManagementConfig0.positionManager();

      positionManager = PositionManager.attach(positionManagerAddress);
      console.log("position manager address", positionManager.address);

      console.log("portfolio deployed to:", portfolio.address);
    });

    describe("Deposit Tests", function () {
      it("should create new position", async () => {
        // UniswapV3 position
        const token0 = addresses.DAI;
        const token1 = addresses.USDC;

        await positionManager.createNewWrapperPosition(
          token0,
          token1,
          "Test",
          "t",
          "100",
          MIN_TICK,
          MAX_TICK
        );

        position1 = await positionManager.deployedPositionWrappers(0);

        const PositionWrapper = await ethers.getContractFactory(
          "PositionWrapper"
        );
        positionWrapper = PositionWrapper.attach(position1);
      });

      it("should init tokens", async () => {
        await portfolio.initToken([addresses.USDC, position1]);

        positionWrappers = [position1];
        swapTokens = [
          addresses.USDC,
          addresses.DAI, // position1 - token0
          addresses.USDC, // position1 - token1
        ];
        positionWrapperIndex = [1];
        portfolioTokenIndex = [0, 1, 1];
        isExternalPosition = [false, true, true];
        index0 = [1];
        index1 = [2];
      });

      it("owner should approve tokens to permit2 contract", async () => {
        const tokens = await portfolio.getTokens();
        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        for (let i = 0; i < tokens.length; i++) {
          await ERC20.attach(tokens[i]).approve(
            PERMIT2_ADDRESS,
            MaxAllowanceTransferAmount
          );

          await ERC20.attach(tokens[i])
            .connect(nonOwner)
            .approve(PERMIT2_ADDRESS, MaxAllowanceTransferAmount);
        }
      });

      it("should swap tokens for user using native token", async () => {
        let tokens = await portfolio.getTokens();

        console.log("SupplyBefore", await portfolio.totalSupply());

        let postResponse: string[] = [];
        let ethSwapAmounts = [];

        for (let i = 0; i < swapTokens.length; i++) {
          ethSwapAmounts.push("2000000000000000");
          let response = await createMetaAggregatorCalldata(
            depositBatch.address,
            depositBatch.address,
            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            swapTokens[i],
            "2000000000000000"
          );
          const zeroXQuote = response?.data?.quotes?.find(
            (quote: { protocol: string }) => quote.protocol === "zeroX"
          );

          postResponse.push(zeroXQuote.data);
        }

        const data = await depositBatch.multiTokenSwapETHAndTransfer(
          {
            _minMintAmount: 0,
            _depositAmount: "4000000000000000",
            _ethSwapAmounts: ethSwapAmounts,
            _target: portfolio.address,
            _depositToken: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            _callData: postResponse,
          },
          {
            _positionWrappers: positionWrappers,
            _swapTokens: swapTokens,
            _positionWrapperIndex: positionWrapperIndex,
            _portfolioTokenIndex: portfolioTokenIndex,
            _index0: index0,
            _index1: index1,
            _amount0Min: [0],
            _amount1Min: [0],
            _isExternalPosition: isExternalPosition,
            _tokenIn: [ZERO_ADDRESS],
            _tokenOut: [ZERO_ADDRESS],
            _amountIn: ["0"],
          },
          {
            value: "1000000000000000000",
          }
        );

        console.log("SupplyAfter", await portfolio.totalSupply());
      });

      it("should swap tokens for user using one of the portfolio token", async () => {
        let tokens = await portfolio.getTokens();

        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");

        const tokenToSwap = addresses.USDC;

        await swapHandler.swapETHToTokens("500", tokenToSwap, owner.address, {
          value: "100000000000000000",
        });

        console.log("SupplyBefore", await portfolio.totalSupply());

        let postResponse: string[] = [];

        let amountToSwap = await ERC20.attach(tokenToSwap).balanceOf(
          owner.address
        );
        let ethSwapAmounts = [];

        for (let i = 0; i < swapTokens.length; i++) {
          let amountIn = BigNumber.from(amountToSwap).div(swapTokens.length);
          ethSwapAmounts.push(0);

          if (tokenToSwap == swapTokens[i]) {
            const abiCoder = ethers.utils.defaultAbiCoder;
            const encodedata = abiCoder.encode(["uint"], [amountIn]);
            postResponse.push(encodedata);
          } else {
            let response = await createMetaAggregatorCalldata(
              depositBatch.address,
              depositBatch.address,
              tokenToSwap,
              swapTokens[i],
              Number(amountIn)
            );
            interface Quote {
              protocol: string;
              data: string;
            }

            const zeroXQuote: Quote | undefined = response?.data?.quotes?.find(
              (quote: Quote) => quote.protocol === "zeroX"
            );

            if (!zeroXQuote?.data) {
              throw new Error("No valid zeroX quote found");
            }

            postResponse.push(zeroXQuote.data);
          }
        }

        //----------Approval-------------

        await ERC20.attach(tokenToSwap).approve(
          depositManager.address,
          amountToSwap.toString()
        );

        await depositManager.deposit(
          {
            _minMintAmount: 0,
            _depositAmount: amountToSwap.toString(),
            _ethSwapAmounts: ethSwapAmounts,
            _target: portfolio.address,
            _depositToken: tokenToSwap,
            _callData: postResponse,
          },
          {
            _positionWrappers: positionWrappers,
            _swapTokens: swapTokens,
            _positionWrapperIndex: positionWrapperIndex,
            _portfolioTokenIndex: portfolioTokenIndex,
            _index0: index0,
            _index1: index1,
            _amount0Min: [0],
            _amount1Min: [0],
            _isExternalPosition: isExternalPosition,
            _tokenIn: [ZERO_ADDRESS],
            _tokenOut: [ZERO_ADDRESS],
            _amountIn: ["0"],
          }
        );

        console.log("SupplyAfter", await portfolio.totalSupply());
      });

      it("should rebalance", async () => {
        let tokens = await portfolio.getTokens();
        let sellToken = tokens[0];
        let buyToken = addresses.DAI;

        let newTokens = [buyToken, tokens[1]];

        let vault = await portfolio.vault();

        let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        let balance = BigNumber.from(
          await ERC20.attach(sellToken).balanceOf(vault)
        ).toString();

        const postResponse = await createMetaAggregatorCalldata(
          metaAggregatorHandler.address,
          metaAggregatorHandler.address,
          sellToken,
          buyToken,
          balance
        );

        const encodedParameters = ethers.utils.defaultAbiCoder.encode(
          [
            " bytes[][]", // callDataEnso
            "bytes[]", // callDataDecreaseLiquidity
            "bytes[][]", // callDataIncreaseLiquidity
            "address[][]", // increaseLiquidityTarget
            "address[]", // underlyingTokensDecreaseLiquidity
            "address[]", // tokensIn
            "address[]", // tokens
            "uint256[][]", // swapAmounts
            "uint256[]", // minExpectedOutputAmounts
          ],
          [
            [[postResponse.data.quotes[1].data]],
            [],
            [[]],
            [[]],
            [],
            [sellToken],
            [buyToken],
            [[balance]],
            [0],
          ]
        );

        await rebalancing.updateTokens({
          _newTokens: newTokens,
          _sellTokens: [sellToken],
          _sellAmounts: [balance],
          _handler: metaAggregatorHandler.address,
          _callData: encodedParameters,
        });

        swapTokens = [
          addresses.DAI,
          addresses.DAI, // position1 - token0
          addresses.USDC, // position1 - token1
        ];

        console.log(
          "balance after sell",
          await ERC20.attach(sellToken).balanceOf(vault)
        );
      });

      it("should withdraw in single token by user", async () => {
        await ethers.provider.send("evm_increaseTime", [62]);

        const supplyBefore = await portfolio.totalSupply();
        const user = owner;
        const tokenToSwapInto = addresses.USDC;

        let responses = [];

        const amountPortfolioToken = BigNumber.from(
          await portfolio.balanceOf(user.address)
        );

        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");

        const balanceBefore = await ERC20.attach(tokenToSwapInto).balanceOf(
          user.address
        );

        const tokens = await portfolio.getTokens();

        let userBalanceBefore = [];

        let withdrawalAmounts =
          await portfolioCalculations.getWithdrawalAmounts(
            amountPortfolioToken,
            portfolio.address
          );

        await portfolio.approve(
          withdrawManager.address,
          BigNumber.from(amountPortfolioToken)
        );

        let swapAmounts = [];
        let wrapperIndex = 0;
        for (let i = 0; i < tokens.length; i++) {
          // only push one amount
          if (!isExternalPosition[i]) {
            swapAmounts.push(withdrawalAmounts[i]);
          } else {
            const PositionWrapper = await ethers.getContractFactory(
              "PositionWrapper"
            );
            const positionWrapperCurrent = PositionWrapper.attach(
              positionWrappers[wrapperIndex]
            );

            const AmountCalculationsAlgebra = await ethers.getContractFactory(
              "AmountCalculationsUniswap"
            );
            const amountCalculationsAlgebra =
              await AmountCalculationsAlgebra.deploy();
            await amountCalculationsAlgebra.deployed();

            let percentage = await amountCalculationsAlgebra.getPercentage(
              withdrawalAmounts[i],
              await positionWrapperCurrent.totalSupply()
            );

            let withdrawAmounts = await calculateOutputAmounts(
              tokens[i],
              percentage.toString()
            );
            if (withdrawAmounts.token0Amount > 0) {
              swapAmounts.push(
                (withdrawAmounts.token0Amount * 0.99999).toFixed(0)
              );
            }
            if (withdrawAmounts.token1Amount > 0) {
              swapAmounts.push(
                (withdrawAmounts.token1Amount * 0.99999).toFixed(0)
              );
            }
            wrapperIndex++;
          }
        }

        for (let i = 0; i < swapTokens.length; i++) {
          swapAmounts.push(swapAmounts[i]);
          if (swapTokens[i] == tokenToSwapInto) {
            responses.push("0x");
          } else {
            let response = await createMetaAggregatorCalldata(
              withdrawBatch.address,
              user.address,
              swapTokens[i],
              tokenToSwapInto,
              (swapAmounts[i] * 0.99999).toFixed(0)
            );

            interface Quote {
              protocol: string;
              data: string;
            }

            const zeroXQuote: Quote | undefined = response?.data?.quotes?.find(
              (quote: Quote) => quote.protocol === "zeroX"
            );

            if (!zeroXQuote?.data) {
              throw new Error("No valid zeroX quote found");
            }

            responses.push(zeroXQuote.data);
          }
          userBalanceBefore.push(
            await ERC20.attach(tokens[i]).balanceOf(user.address)
          );
        }

        await withdrawManager.withdraw(
          swapTokens,
          portfolio.address,
          tokenToSwapInto,
          amountPortfolioToken,
          swapAmounts,
          responses,
          0,
          {
            _factory: ensoHandler.address,
            _token0: zeroAddress, //USDT - Pool token
            _token1: zeroAddress, //USDC - Pool token
            _flashLoanToken: zeroAddress, //Token to take flashlaon
            _bufferUnit: "0",
            _solverHandler: ensoHandler.address, //Handler to swap
            _flashLoanAmount: [0],
            firstSwapData: ["0x"],
            secondSwapData: ["0x"],
          },
          {
            _positionWrappers: positionWrappers,
            _amountsMin0: [0],
            _amountsMin1: [0],
            _tokenIn: [ZERO_ADDRESS],
            _tokenOut: [ZERO_ADDRESS],
            _amountIn: ["0"],
          }
        );

        const balanceAfter = await ERC20.attach(tokenToSwapInto).balanceOf(
          user.address
        );

        const supplyAfter = await portfolio.totalSupply();

        expect(Number(balanceAfter)).to.be.greaterThan(Number(balanceBefore));
        expect(Number(supplyBefore)).to.be.greaterThan(Number(supplyAfter));
      });
    });
  });
});
