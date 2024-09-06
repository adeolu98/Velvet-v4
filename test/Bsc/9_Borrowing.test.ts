import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect, use } from "chai";
import "@nomicfoundation/hardhat-chai-matchers";
import { ethers, network, upgrades } from "hardhat";
import { BigNumber, Contract } from "ethers";
import VENUS_CHAINLINK_ORACLE_ABI from "../abi/venus_chainlink_oracle.json";

import {
  createEnsoCallData,
  createEnsoCallDataRoute,
} from "./IntentCalculations";

import { tokenAddresses, IAddresses, priceOracle } from "./Deployments.test";

import {
  Portfolio,
  Portfolio__factory,
  ProtocolConfig,
  Rebalancing__factory,
  PortfolioFactory,
  UniswapV2Handler,
  VelvetSafeModule,
  FeeModule,
  FeeModule__factory,
  EnsoHandler,
  EnsoHandlerBundled,
  AccessController__factory,
  TokenExclusionManager__factory,
  TokenBalanceLibrary,
  BorrowManager,
  DepositBatch,
  DepositManager,
  WithdrawBatch,
  WithdrawManager,
  VenusAssetHandler,
  IAssetHandler,
} from "../../typechain";

import { chainIdToAddresses } from "../../scripts/networkVariables";

var chai = require("chai");
const axios = require("axios");
const qs = require("qs");
//use default BigNumber
chai.use(require("chai-bignumber")());

describe.only("Tests for Deposit", () => {
  let accounts;
  let iaddress: IAddresses;
  let vaultAddress: string;
  let velvetSafeModule: VelvetSafeModule;
  let portfolio: any;
  let portfolio1: any;
  let portfolioCalculations: any;
  let tokenExclusionManager: any;
  let tokenExclusionManager1: any;
  let borrowManager: BorrowManager;
  let ensoHandler: EnsoHandler;
  let depositBatch: DepositBatch;
  let depositManager: DepositManager;
  let venusAssetHandler: VenusAssetHandler;
  let withdrawBatch: WithdrawBatch;
  let withdrawManager: WithdrawManager;
  let portfolioContract: Portfolio;
  let comptroller: Contract;
  let portfolioFactory: PortfolioFactory;
  let swapHandler: UniswapV2Handler;
  let rebalancing: any;
  let rebalancing1: any;
  let tokenBalanceLibrary: TokenBalanceLibrary;
  let protocolConfig: ProtocolConfig;
  let positionWrapper: any;
  let fakePortfolio: Portfolio;
  let txObject;
  let owner: SignerWithAddress;
  let treasury: SignerWithAddress;
  let _assetManagerTreasury: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let depositor1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addrs: SignerWithAddress[];
  let feeModule0: FeeModule;
  const assetManagerHash = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("ASSET_MANAGER")
  );

  const provider = ethers.provider;
  const chainId: any = process.env.CHAIN_ID;
  const addresses = chainIdToAddresses[chainId];

  function delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  describe.only("Tests for Deposit", () => {
    before(async () => {
      accounts = await ethers.getSigners();
      [
        owner,
        depositor1,
        nonOwner,
        treasury,
        _assetManagerTreasury,
        addr1,
        addr2,
        ...addrs
      ] = accounts;

      iaddress = await tokenAddresses();

      const EnsoHandler = await ethers.getContractFactory("EnsoHandler");
      ensoHandler = await EnsoHandler.deploy();
      await ensoHandler.deployed();

      const DepositBatch = await ethers.getContractFactory("DepositBatch");
      depositBatch = await DepositBatch.deploy();
      await depositBatch.deployed();

      const DepositManager = await ethers.getContractFactory("DepositManager");
      depositManager = await DepositManager.deploy(depositBatch.address);
      await depositManager.deployed();

      const WithdrawBatch = await ethers.getContractFactory("WithdrawBatch");
      withdrawBatch = await WithdrawBatch.deploy();
      await withdrawBatch.deployed();

      const WithdrawManager = await ethers.getContractFactory(
        "WithdrawManager"
      );
      withdrawManager = await WithdrawManager.deploy();
      await withdrawManager.deployed();

      const TokenBalanceLibrary = await ethers.getContractFactory(
        "TokenBalanceLibrary"
      );

      tokenBalanceLibrary = await TokenBalanceLibrary.deploy();
      tokenBalanceLibrary.deployed();

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

      const chainLinkOracle = "0x1B2103441A0A108daD8848D8F5d790e4D402921F";

      let oracle = new ethers.Contract(
        chainLinkOracle,
        VENUS_CHAINLINK_ORACLE_ABI,
        owner.provider
      );

      let oracleOwner = await oracle.owner();

      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [oracleOwner],
      });
      const oracleSigner = await ethers.getSigner(oracleOwner);

      const tx = await oracle.connect(oracleSigner).setTokenConfigs([
        {
          asset: "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
          feed: "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE",
          maxStalePeriod: "31536000",
        },
        {
          asset: "0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3",
          feed: "0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA",
          maxStalePeriod: "31536000",
        },
        {
          asset: "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",
          feed: "0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf",
          maxStalePeriod: "31536000",
        },
      ]);
      await tx.wait();

      protocolConfig = ProtocolConfig.attach(_protocolConfig.address);
      await protocolConfig.setCoolDownPeriod("70");
      await protocolConfig.enableSolverHandler(ensoHandler.address);

      await protocolConfig.enableBorrowableTokens([
        addresses.vBNB_Address,
        addresses.vBTC_Address,
        addresses.vDAI_Address,
        addresses.vUSDT_DeFi_Address,
      ]);

      const Rebalancing = await ethers.getContractFactory("Rebalancing", {
        libraries: {
          TokenBalanceLibrary: tokenBalanceLibrary.address,
        },
      });
      const rebalancingDefult = await Rebalancing.deploy();
      await rebalancingDefult.deployed();

      const AssetManagementConfig = await ethers.getContractFactory(
        "AssetManagementConfig"
      );
      const assetManagementConfig = await AssetManagementConfig.deploy();
      await assetManagementConfig.deployed();

      const TokenExclusionManager = await ethers.getContractFactory(
        "TokenExclusionManager"
      );
      const tokenExclusionManagerDefault = await TokenExclusionManager.deploy();
      await tokenExclusionManagerDefault.deployed();

      const Portfolio = await ethers.getContractFactory("Portfolio", {
        libraries: {
          TokenBalanceLibrary: tokenBalanceLibrary.address,
        },
      });
      portfolioContract = await Portfolio.deploy();
      await portfolioContract.deployed();

      const VenusAssetHandler = await ethers.getContractFactory(
        "VenusAssetHandler"
      );
      venusAssetHandler = await VenusAssetHandler.deploy();
      await venusAssetHandler.deployed();

      const BorrowManager = await ethers.getContractFactory("BorrowManager");
      borrowManager = await BorrowManager.deploy();
      await borrowManager.deployed();

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
          venusAssetHandler.address,
          venusAssetHandler.address,
          venusAssetHandler.address,
          venusAssetHandler.address,
          venusAssetHandler.address,
          venusAssetHandler.address,
        ]
      );

      await protocolConfig.setSupportedControllers([
        addresses.corePool_controller,
      ]);

      await protocolConfig.setMarketControllers(
        [
          addresses.vBNB_Address,
          addresses.vBTC_Address,
          addresses.vDAI_Address,
          addresses.vUSDT_Address,
          addresses.vUSDT_DeFi_Address,
        ],
        [
          addresses.corePool_controller,
          addresses.corePool_controller,
          addresses.corePool_controller,
          addresses.corePool_controller,
          addresses.defi_controller,
        ]
      );

      let whitelistedTokens = [
        iaddress.usdcAddress,
        iaddress.btcAddress,
        iaddress.ethAddress,
        iaddress.wbnbAddress,
        iaddress.usdtAddress,
        iaddress.dogeAddress,
        iaddress.daiAddress,
        iaddress.cakeAddress,
        addresses.LINK_Address,
        addresses.DOT,
        addresses.vBTC_Address,
        addresses.vETH_Address,
      ];

      let whitelist = [owner.address];

      const PositionManager = await ethers.getContractFactory(
        "PositionManagerThena"
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

      fakePortfolio = await Portfolio.deploy();
      await fakePortfolio.deployed();

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
            _basePositionManager: positionManagerBaseAddress.address,
            _baseBorrowManager: borrowManager.address,
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
          _assetManagerTreasury: _assetManagerTreasury.address,
          _whitelistedTokens: whitelistedTokens,
          _public: true,
          _transferable: true,
          _transferableToPublic: true,
          _whitelistTokens: false,
        });

      const portfolioFactoryCreate2 = await portfolioFactory
        .connect(nonOwner)
        .createPortfolioNonCustodial({
          _name: "PORTFOLIOLY",
          _symbol: "IDX",
          _managementFee: "200",
          _performanceFee: "2500",
          _entryFee: "10",
          _exitFee: "10",
          _initialPortfolioAmount: "100000000000000000000",
          _minPortfolioTokenHoldingAmount: "10000000000000000",
          _assetManagerTreasury: _assetManagerTreasury.address,
          _whitelistedTokens: whitelistedTokens,
          _public: true,
          _transferable: false,
          _transferableToPublic: false,
          _whitelistTokens: false,
        });
      const portfolioAddress = await portfolioFactory.getPortfolioList(0);
      const portfolioInfo = await portfolioFactory.PortfolioInfolList(0);

      const portfolioAddress1 = await portfolioFactory.getPortfolioList(1);
      const portfolioInfo1 = await portfolioFactory.PortfolioInfolList(1);

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

      portfolio1 = await ethers.getContractAt(
        Portfolio__factory.abi,
        portfolioAddress1
      );

      rebalancing = await ethers.getContractAt(
        Rebalancing__factory.abi,
        portfolioInfo.rebalancing
      );

      rebalancing1 = await ethers.getContractAt(
        Rebalancing__factory.abi,
        portfolioInfo1.rebalancing
      );

      tokenExclusionManager = await ethers.getContractAt(
        TokenExclusionManager__factory.abi,
        portfolioInfo.tokenExclusionManager
      );

      tokenExclusionManager1 = await ethers.getContractAt(
        TokenExclusionManager__factory.abi,
        portfolioInfo1.tokenExclusionManager
      );

      console.log("portfolio deployed to:", portfolio.address);

      console.log("rebalancing:", rebalancing1.address);
    });

    describe("Deposit Tests", function () {
      it("should init tokens", async () => {
        await portfolio.initToken([
          iaddress.wbnbAddress,
          iaddress.btcAddress,
          iaddress.ethAddress,
          iaddress.dogeAddress,
          iaddress.usdcAddress,
          iaddress.cakeAddress,
        ]);
      });

      it("should swap tokens for user using native token", async () => {
        let tokens = await portfolio.getTokens();

        console.log("SupplyBefore", await portfolio.totalSupply());

        let postResponse = [];

        for (let i = 0; i < tokens.length; i++) {
          let response = await createEnsoCallDataRoute(
            depositBatch.address,
            depositBatch.address,
            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            tokens[i],
            "20000000000000000"
          );
          postResponse.push(response.data.tx.data);
        }

        const data = await depositBatch.multiTokenSwapETHAndTransfer(
          {
            _minMintAmount: 0,
            _depositAmount: "1000000000000000000",
            _target: portfolio.address,
            _depositToken: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            _callData: postResponse,
          },
          {
            value: "1000000000000000000",
          }
        );

        console.log("SupplyAfter", await portfolio.totalSupply());
      });

      it("should rebalance to lending token vBNB", async () => {
        let tokens = await portfolio.getTokens();
        let sellToken = tokens[0];
        let buyToken = addresses.vBNB_Address;

        let newTokens = [
          buyToken,
          tokens[1],
          tokens[2],
          tokens[3],
          tokens[4],
          tokens[5],
        ];

        let vault = await portfolio.vault();

        let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        let balance = BigNumber.from(
          await ERC20.attach(sellToken).balanceOf(vault)
        ).toString();

        console.log("Balance to rebalance", balance);

        const postResponse = await createEnsoCallDataRoute(
          ensoHandler.address,
          ensoHandler.address,
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
            " uint256[]", // minExpectedOutputAmounts
          ],
          [
            [[postResponse.data.tx.data]],
            [],
            [[]],
            [[]],
            [],
            [sellToken],
            [buyToken],
            [0],
          ]
        );

        await rebalancing.updateTokens({
          _newTokens: newTokens,
          _sellTokens: [sellToken],
          _sellAmounts: [balance],
          _handler: ensoHandler.address,
          _callData: encodedParameters,
        });

        console.log(
          "balance after sell",
          await ERC20.attach(sellToken).balanceOf(vault)
        );
        console.log(
          "balance after buy",
          await ERC20.attach(buyToken).balanceOf(vault)
        );
      });

      it("should rebalance to lending token vBTC", async () => {
        let tokens = await portfolio.getTokens();
        let sellToken = tokens[1];
        let buyToken = addresses.vBTC_Address;

        let newTokens = [
          tokens[0],
          buyToken,
          tokens[2],
          tokens[3],
          tokens[4],
          tokens[5],
        ];

        let vault = await portfolio.vault();

        let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        let balance = BigNumber.from(
          await ERC20.attach(sellToken).balanceOf(vault)
        ).toString();

        console.log("Balance to rebalance", balance);

        const postResponse = await createEnsoCallDataRoute(
          ensoHandler.address,
          ensoHandler.address,
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
            " uint256[]", // minExpectedOutputAmounts
          ],
          [
            [[postResponse.data.tx.data]],
            [],
            [[]],
            [[]],
            [],
            [sellToken],
            [buyToken],
            [0],
          ]
        );

        await rebalancing.updateTokens({
          _newTokens: newTokens,
          _sellTokens: [sellToken],
          _sellAmounts: [balance],
          _handler: ensoHandler.address,
          _callData: encodedParameters,
        });

        console.log(
          "balance after sell",
          await ERC20.attach(sellToken).balanceOf(vault)
        );
        console.log(
          "balance after buy",
          await ERC20.attach(buyToken).balanceOf(vault)
        );
      });

      it("should swap tokens for user using native token", async () => {
        let tokens = await portfolio.getTokens();

        console.log("SupplyBefore", await portfolio.totalSupply());

        let postResponse = [];

        for (let i = 0; i < tokens.length; i++) {
          let response = await createEnsoCallDataRoute(
            depositBatch.address,
            depositBatch.address,
            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            tokens[i],
            "20000000000000000"
          );
          postResponse.push(response.data.tx.data);
        }

        const data = await depositBatch.multiTokenSwapETHAndTransfer(
          {
            _minMintAmount: 0,
            _depositAmount: "1000000000000000000",
            _target: portfolio.address,
            _depositToken: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            _callData: postResponse,
          },
          {
            value: "1000000000000000000",
          }
        );

        console.log("SupplyAfter", await portfolio.totalSupply());
      });

      it("should borrow USDT using vBNB as collateral", async () => {
        let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        let vault = await portfolio.vault();
        let tokens = await portfolio.getTokens();
        console.log(
          "DAI Balance before",
          await ERC20.attach(addresses.USDT).balanceOf(vault)
        );

        const newTokens = [...tokens, addresses.USDT];
        await rebalancing.borrow(
          addresses.vUSDT_Address,
          addresses.vBNB_Address,
          addresses.USDT,
          "1000000000000000000",
          newTokens
        );
        console.log(
          "DAI Balance after",
          await ERC20.attach(addresses.USDT).balanceOf(vault)
        );

        console.log("newtokens", await portfolio.getTokens());
      });

      it("should borrow DAI using vBNB as collateral", async () => {
        let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        let vault = await portfolio.vault();
        let tokens = await portfolio.getTokens();
        console.log(
          "DAI Balance before",
          await ERC20.attach(addresses.DAI_Address).balanceOf(vault)
        );

        const newTokens = [...tokens, addresses.DAI_Address];
        await rebalancing.borrow(
          addresses.vDAI_Address,
          addresses.vBNB_Address,
          addresses.DAI_Address,
          "1000000000000000000",
          newTokens
        );
        console.log(
          "DAI Balance after",
          await ERC20.attach(addresses.DAI_Address).balanceOf(vault)
        );

        console.log("newtokens", await portfolio.getTokens());
      });

      it("should swap tokens for user using native token", async () => {
        let tokens = await portfolio.getTokens();

        console.log("SupplyBefore", await portfolio.totalSupply());

        let postResponse = [];

        for (let i = 0; i < tokens.length; i++) {
          let response = await createEnsoCallDataRoute(
            depositBatch.address,
            depositBatch.address,
            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            tokens[i],
            "20000000000000000"
          );
          postResponse.push(response.data.tx.data);
        }

        const data = await depositBatch
          .connect(nonOwner)
          .multiTokenSwapETHAndTransfer(
            {
              _minMintAmount: 0,
              _depositAmount: "1000000000000000000",
              _target: portfolio.address,
              _depositToken: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
              _callData: postResponse,
            },
            {
              value: "1000000000000000000",
            }
          );

        console.log("SupplyAfter", await portfolio.totalSupply());
      });

      it("Repay half of borrowed amount", async () => {
        let vault = await portfolio.vault();
        let ERC20 = await ethers.getContractFactory("ERC20Upgradeable");

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

        console.log(
          "Balance of vToken before",
          await ERC20.attach(addresses.vBNB_Address).balanceOf(vault)
        );

        const balanceToRepay = (balanceBorrowed[0] / 2).toString();
        const balanceToSwap = balanceToRepay;

        console.log("flashlaonAmount", balanceToSwap);
        console.log("balanceToRepay", balanceToRepay);

        const postResponse = await createEnsoCallDataRoute(
          ensoHandler.address,
          ensoHandler.address,
          addresses.USDT,
          addresses.DAI_Address,
          balanceToSwap
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
            " uint256[]", // minExpectedOutputAmounts
          ],
          [
            [["0x"]],
            [],
            [[]],
            [[]],
            [],
            [addresses.USDT],
            [addresses.DAI_Address],
            [0],
          ]
        );

        let encodedParameters1 = [];
        //Because repay(rebalance) is one borrow token at a time
        const amounToSell =
          await portfolioCalculations.getCollateralAmountToSell(
            vault,
            addresses.corePool_controller,
            venusAssetHandler.address,
            addresses.vUSDT_Address,
            balanceToRepay,
            "10"
          );
        for (let j = 0; j < lendTokens.length; j++) {
          console.log("amountToSell", amounToSell[j].toString());

          const postResponse1 = await createEnsoCallDataRoute(
            ensoHandler.address,
            ensoHandler.address,
            lendTokens[j],
            addresses.USDT,
            amounToSell[j].toString() //Need calculation here
          );

          encodedParameters1.push(
            ethers.utils.defaultAbiCoder.encode(
              [
                "bytes[][]", // callDataEnso
                "bytes[]", // callDataDecreaseLiquidity
                "bytes[][]", // callDataIncreaseLiquidity
                "address[][]", // increaseLiquidityTarget
                "address[]", // underlyingTokensDecreaseLiquidity
                "address[]", // tokensIn
                "address[]", // tokens
                " uint256[]", // minExpectedOutputAmounts
              ],
              [
                [[postResponse1.data.tx.data]],
                [],
                [[]],
                [[]],
                [],
                [lendTokens[j]],
                [addresses.USDT],
                [0],
              ]
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
          _solverHandler: ensoHandler.address, //Handler to swap
          _flashLoanAmount: [balanceToSwap],
          _debtRepayAmount: [balanceToRepay],
          firstSwapData: [encodedParameters],
          secondSwapData: encodedParameters1,
        });

        console.log(
          "Balance of vToken After",
          await ERC20.attach(addresses.vBNB_Address).balanceOf(vault)
        );

        balanceBorrowed =
          await portfolioCalculations.getVenusTokenBorrowedBalance(
            [addresses.vUSDT_Address],
            vault
          );

        console.log("balanceBorrowed after repay", balanceBorrowed);
      });

      it("should withdraw in BTC by owner(user1)", async () => {
        await ethers.provider.send("evm_increaseTime", [70]);

        const supplyBefore = await portfolio.totalSupply();
        const tokenToSwapInto = iaddress.btcAddress;

        const user = owner;

        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        const tokens = await portfolio.getTokens();

        let vault = await portfolio.vault();

        let flashLoanToken = addresses.USDT;
        let flashLoanProtocolToken = addresses.vUSDT_Address;

        const amountPortfolioToken = await portfolio.balanceOf(user.address);

        console.log("amountPortfolioToken", amountPortfolioToken);

        let withdrawalAmounts =
          await portfolioCalculations.getWithdrawalAmounts(
            amountPortfolioToken,
            portfolio.address
          );

        await portfolio.approve(
          withdrawManager.address,
          BigNumber.from(amountPortfolioToken)
        );
        let responses = [];
        let userBalanceBefore = [];
        for (let i = 0; i < tokens.length; i++) {
          if (tokens[i] == tokenToSwapInto) {
            responses.push("0x");
          } else {
            let response = await createEnsoCallDataRoute(
              withdrawBatch.address,
              user.address,
              tokens[i],
              tokenToSwapInto,
              (withdrawalAmounts[i] * 0.993).toFixed(0)
            );
            responses.push(response.data.tx.data);
          }
          userBalanceBefore.push(
            await ERC20.attach(tokens[i]).balanceOf(user.address)
          );
        }

        const values =
          await portfolioCalculations.getBorrowedPortionAndFlashLoanAmountOfUser(
            portfolio.address,
            flashLoanProtocolToken,
            vault,
            amountPortfolioToken,
            addresses.corePool_controller,
            venusAssetHandler.address
          );

        const borrowedPortion = values[0];
        const flashLoanAmount = values[1];
        const underlyings = values[2];
        const borrowedTokens = values[3];

        const userData = await venusAssetHandler.getUserAccountData(
          vault,
          addresses.corePool_controller
        );
        const lendTokens = userData[1].lendTokens;

        // console.log("values", values);

        let balanceBorrowed =
          await portfolioCalculations.getVenusTokenBorrowedBalance(
            [addresses.vUSDT_Address],
            vault
          );

        console.log("balanceBorrowed before withdraw", balanceBorrowed);

        console.log(
          "Balance of vToken before",
          await ERC20.attach(addresses.vBNB_Address).balanceOf(vault)
        );

        let tokenBalanceBefore: any = [];
        for (let i = 0; i < tokens.length; i++) {
          tokenBalanceBefore[i] = await ERC20.attach(tokens[i]).balanceOf(
            owner.address
          );
        }

        let encodedParameters = [];
        let encodedParameters1 = [];
        for (let i = 0; i < flashLoanAmount.length; i++) {
          console.log("underlyings token", underlyings[i]);
          if (flashLoanToken != underlyings[i]) {
            const postResponse = await createEnsoCallDataRoute(
              ensoHandler.address,
              ensoHandler.address,
              flashLoanToken,
              underlyings[i],
              flashLoanAmount[i].toString()
            );
            encodedParameters.push(
              ethers.utils.defaultAbiCoder.encode(
                [
                  "bytes[][]", // callDataEnso
                  "bytes[]", // callDataDecreaseLiquidity
                  "bytes[][]", // callDataIncreaseLiquidity
                  "address[][]", // increaseLiquidityTarget
                  "address[]", // underlyingTokensDecreaseLiquidity
                  "address[]", // tokensIn
                  "address[]", // tokens
                  " uint256[]", // minExpectedOutputAmounts
                ],
                [
                  [[postResponse.data.tx.data]],
                  [],
                  [[]],
                  [[]],
                  [],
                  [flashLoanToken],
                  [underlyings[i]],
                  [0],
                ]
              )
            );
          } else {
            encodedParameters.push(
              ethers.utils.defaultAbiCoder.encode(
                [
                  " bytes[][]", // callDataEnso
                  "bytes[]", // callDataDecreaseLiquidity
                  "bytes[][]", // callDataIncreaseLiquidity
                  "address[][]", // increaseLiquidityTarget
                  "address[]", // underlyingTokensDecreaseLiquidity
                  "address[]", // tokensIn
                  "address[]", // tokens
                  " uint256[]", // minExpectedOutputAmounts
                ],
                [
                  [[]],
                  [],
                  [],
                  [[]],
                  [],
                  [flashLoanToken],
                  [underlyings[i]],
                  [0],
                ]
              )
            );
          }

          const amounToSell =
            await portfolioCalculations.getCollateralAmountToSell(
              vault,
              addresses.corePool_controller,
              venusAssetHandler.address,
              borrowedTokens[i],
              borrowedPortion[i],
              "10"
            );

          for (let j = 0; j < lendTokens.length; j++) {
            const postResponse1 = await createEnsoCallDataRoute(
              ensoHandler.address,
              ensoHandler.address,
              lendTokens[j],
              flashLoanToken,
              amounToSell[j].toString() //Need calculation here
            );

            encodedParameters1.push(
              ethers.utils.defaultAbiCoder.encode(
                [
                  "bytes[][]", // callDataEnso
                  "bytes[]", // callDataDecreaseLiquidity
                  "bytes[][]", // callDataIncreaseLiquidity
                  "address[][]", // increaseLiquidityTarget
                  "address[]", // underlyingTokensDecreaseLiquidity
                  "address[]", // tokensIn
                  "address[]", // tokens
                  " uint256[]", // minExpectedOutputAmounts
                ],
                [
                  [[postResponse1.data.tx.data]],
                  [],
                  [[]],
                  [[]],
                  [],
                  [lendTokens[j]],
                  [flashLoanToken],
                  [0],
                ]
              )
            );
          }
        }

        await withdrawManager.withdraw(
          portfolio.address,
          tokenToSwapInto,
          amountPortfolioToken,
          {
            _factory: addresses.thena_factory,
            _token0: addresses.USDT, //USDT - Pool token
            _token1: addresses.USDC_Address, //USDC - Pool token
            _flashLoanToken: flashLoanToken, //Token to take flashlaon
            _solverHandler: ensoHandler.address, //Handler to swap
            _flashLoanAmount: flashLoanAmount,
            firstSwapData: encodedParameters,
            secondSwapData: encodedParameters1,
          },
          responses
        );

        const supplyAfter = await portfolio.totalSupply();
        console.log("SupplyAfter", supplyAfter);

        for (let i = 0; i < tokens.length; i++) {
          let balanceAfter = await ERC20.attach(tokens[i]).balanceOf(
            owner.address
          );
          let balanceOFHandler = await ERC20.attach(tokens[i]).balanceOf(
            withdrawBatch.address
          );
          expect(Number(balanceAfter)).to.be.greaterThan(
            Number(userBalanceBefore[i])
          );
          expect(Number(balanceOFHandler)).to.be.equal(0);
        }

        expect(Number(supplyBefore)).to.be.greaterThan(Number(supplyAfter));
      });

      it("should withdraw in ETH by non-owner(user2)", async () => {
        await ethers.provider.send("evm_increaseTime", [70]);

        const supplyBefore = await portfolio.totalSupply();

        const tokenToSwapInto = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";

        const user = nonOwner;

        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        const tokens = await portfolio.getTokens();

        let vault = await portfolio.vault();

        let flashLoanToken = addresses.USDT;
        let flashLoanProtocolToken = addresses.vUSDT_Address;

        const amountPortfolioToken = await portfolio.balanceOf(user.address);

        console.log("amountPortfolioToken", amountPortfolioToken);

        let withdrawalAmounts =
          await portfolioCalculations.getWithdrawalAmounts(
            amountPortfolioToken,
            portfolio.address
          );

        await portfolio
          .connect(user)
          .approve(
            withdrawManager.address,
            BigNumber.from(amountPortfolioToken)
          );
        let responses = [];
        let userBalanceBefore = [];
        for (let i = 0; i < tokens.length; i++) {
          if (tokens[i] == tokenToSwapInto) {
            responses.push("0x");
          } else {
            let response = await createEnsoCallDataRoute(
              withdrawBatch.address,
              user.address,
              tokens[i],
              tokenToSwapInto,
              (withdrawalAmounts[i] * 0.993).toFixed(0)
            );
            responses.push(response.data.tx.data);
          }
          userBalanceBefore.push(
            await ERC20.attach(tokens[i]).balanceOf(user.address)
          );
        }

        const values =
          await portfolioCalculations.getBorrowedPortionAndFlashLoanAmountOfUser(
            portfolio.address,
            flashLoanProtocolToken,
            vault,
            amountPortfolioToken,
            addresses.corePool_controller,
            venusAssetHandler.address
          );

        const borrowedPortion = values[0];
        const flashLoanAmount = values[1];
        const underlyings = values[2];
        const borrowedTokens = values[3];

        const userData = await venusAssetHandler.getUserAccountData(
          vault,
          addresses.corePool_controller
        );
        const lendTokens = userData[1].lendTokens;

        // console.log("values", values);

        let balanceBorrowed =
          await portfolioCalculations.getVenusTokenBorrowedBalance(
            [addresses.vUSDT_Address],
            vault
          );

        console.log("balanceBorrowed before withdraw", balanceBorrowed);

        console.log(
          "Balance of vToken before",
          await ERC20.attach(addresses.vBNB_Address).balanceOf(vault)
        );

        let tokenBalanceBefore: any = [];
        for (let i = 0; i < tokens.length; i++) {
          tokenBalanceBefore[i] = await ERC20.attach(tokens[i]).balanceOf(
            user.address
          );
        }

        let encodedParameters = [];
        let encodedParameters1 = [];
        for (let i = 0; i < flashLoanAmount.length; i++) {
          console.log("underlyings token", underlyings[i]);
          if (flashLoanToken != underlyings[i]) {
            const postResponse = await createEnsoCallDataRoute(
              ensoHandler.address,
              ensoHandler.address,
              flashLoanToken,
              underlyings[i],
              flashLoanAmount[i].toString()
            );
            encodedParameters.push(
              ethers.utils.defaultAbiCoder.encode(
                [
                  " bytes[][]", // callDataEnso
                  "bytes[]", // callDataDecreaseLiquidity
                  "bytes[][]", // callDataIncreaseLiquidity
                  "address[][]", // increaseLiquidityTarget
                  "address[]", // underlyingTokensDecreaseLiquidity
                  "address[]", // tokensIn
                  "address[]", // tokens
                  " uint256[]", // minExpectedOutputAmounts
                ],
                [
                  [[postResponse.data.tx.data]],
                  [],
                  [[]],
                  [[]],
                  [],
                  [flashLoanToken],
                  [underlyings[i]],
                  [0],
                ]
              )
            );
          } else {
            encodedParameters.push(
              ethers.utils.defaultAbiCoder.encode(
                [
                  "bytes[][]", // callDataEnso
                  "bytes[]", // callDataDecreaseLiquidity
                  "bytes[][]", // callDataIncreaseLiquidity
                  "address[][]", // increaseLiquidityTarget
                  "address[]", // underlyingTokensDecreaseLiquidity
                  "address[]", // tokensIn
                  "address[]", // tokens
                  " uint256[]", // minExpectedOutputAmounts
                ],
                [
                  [["0x"]],
                  [],
                  [[]],
                  [[]],
                  [],
                  [flashLoanToken],
                  [underlyings[i]],
                  [0],
                ]
              )
            );
          }

          const amounToSell =
            await portfolioCalculations.getCollateralAmountToSell(
              vault,
              addresses.corePool_controller,
              venusAssetHandler.address,
              borrowedTokens[i],
              borrowedPortion[i],
              "10"
            );

          for (let j = 0; j < lendTokens.length; j++) {
            const postResponse1 = await createEnsoCallDataRoute(
              ensoHandler.address,
              ensoHandler.address,
              lendTokens[j],
              flashLoanToken,
              amounToSell[j].toString() //Need calculation here
            );

            encodedParameters1.push(
              ethers.utils.defaultAbiCoder.encode(
                [
                  "bytes[][]", // callDataEnso
                  "bytes[]", // callDataDecreaseLiquidity
                  "bytes[][]", // callDataIncreaseLiquidity
                  "address[][]", // increaseLiquidityTarget
                  "address[]", // underlyingTokensDecreaseLiquidity
                  "address[]", // tokensIn
                  "address[]", // tokens
                  " uint256[]", // minExpectedOutputAmounts
                ],
                [
                  [[postResponse1.data.tx.data]],
                  [],
                  [[]],
                  [[]],
                  [],
                  [lendTokens[j]],
                  [flashLoanToken],
                  [0],
                ]
              )
            );
          }
        }

        await withdrawManager.connect(user).withdraw(
          portfolio.address,
          tokenToSwapInto,
          amountPortfolioToken,
          {
            _factory: addresses.thena_factory,
            _token0: addresses.USDT, //USDT - Pool token
            _token1: addresses.USDC_Address, //USDC - Pool token
            _flashLoanToken: flashLoanToken, //Token to take flashlaon
            _solverHandler: ensoHandler.address, //Handler to swap
            _flashLoanAmount: flashLoanAmount,
            firstSwapData: encodedParameters,
            secondSwapData: encodedParameters1,
          },
          responses
        );

        const supplyAfter = await portfolio.totalSupply();
        console.log("SupplyAfter", supplyAfter);

        for (let i = 0; i < tokens.length; i++) {
          let balanceAfter = await ERC20.attach(tokens[i]).balanceOf(
            user.address
          );
          let balanceOfHandler = await ERC20.attach(tokens[i]).balanceOf(
            withdrawBatch.address
          );
          expect(Number(balanceAfter)).to.be.greaterThan(
            Number(userBalanceBefore[i])
          );
          expect(Number(balanceOfHandler)).to.be.equal(0);
        }

        expect(Number(supplyBefore)).to.be.greaterThan(Number(supplyAfter));
      });
    });
  });
});
