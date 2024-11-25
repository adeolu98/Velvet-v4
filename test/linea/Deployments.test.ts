import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { chainIdToAddresses } from "../../scripts/networkVariables";
import {
  IERC20Upgradeable__factory,
  ProtocolConfig,
  AccessController,
  VelvetSafeModule,
  PriceOracle,
} from "../../typechain";

let protocolConfig: ProtocolConfig;
let accessController: AccessController;
let priceOracle: PriceOracle;
let owner: SignerWithAddress;
let treasury: SignerWithAddress;
let wbnbAddress: string;
let busdAddress: string;
let daiAddress: string;
let ethAddress: string;
let btcAddress: string;
let dogeAddress: string;
let linkAddress: string;
let cakeAddress: string;
let usdtAddress: string;
let usdcAddress: string;
let accounts;
let velvetSafeModule: VelvetSafeModule;

const forkChainId: any = process.env.FORK_CHAINID;
const chainId: any = forkChainId ? forkChainId : 59144;
const addresses = chainIdToAddresses[chainId];

export type IAddresses = {
  wbnbAddress: string;
  busdAddress: string;
  daiAddress: string;
  ethAddress: string;
  btcAddress: string;
  linkAddress: string;
  cakeAddress: string;
  usdtAddress: string;
  usdcAddress: string;
};

export async function tokenAddresses(): Promise<IAddresses> {
  let Iaddress: IAddresses;

  const wbnbInstance = new ethers.Contract(
    addresses.WETH_Address,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  wbnbAddress = wbnbInstance.address;

  const busdInstance = new ethers.Contract(
    addresses.BUSD,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  busdAddress = busdInstance.address;

  const daiInstance = new ethers.Contract(
    addresses.DAI_Address,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  daiAddress = daiInstance.address;

  const ethInstance = new ethers.Contract(
    addresses.ETH_Address,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  ethAddress = ethInstance.address;

  const btcInstance = new ethers.Contract(
    addresses.BTC_Address,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  btcAddress = btcInstance.address;

  const linkInstance = new ethers.Contract(
    addresses.LINK_Address,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  linkAddress = linkInstance.address;

  const cakeInstance = new ethers.Contract(
    addresses.CAKE_Address,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  cakeAddress = cakeInstance.address;

  const usdcInstance = new ethers.Contract(
    addresses.USDC_Address,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  usdcAddress = usdcInstance.address;

  const usdtInstance = new ethers.Contract(
    addresses.USDT,
    IERC20Upgradeable__factory.abi,
    ethers.getDefaultProvider()
  );
  usdtAddress = usdtInstance.address;

  Iaddress = {
    wbnbAddress,
    busdAddress,
    daiAddress,
    ethAddress,
    btcAddress,
    linkAddress,
    cakeAddress,
    usdtAddress,
    usdcAddress,
  };

  return Iaddress;
}

before(async () => {
  accounts = await ethers.getSigners();
  [owner, treasury] = accounts;

  const provider = ethers.getDefaultProvider();

  const AccessController = await ethers.getContractFactory("AccessController");
  accessController = await AccessController.deploy();
  await accessController.deployed();

  const PriceOracle = await ethers.getContractFactory("PriceOracle");
  priceOracle = await PriceOracle.deploy(
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
  );
  await priceOracle.deployed();

  await priceOracle.setFeeds(
    [
      addresses.WETH_Address,
      addresses.DAI_Address,
      "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      addresses.BTC_Address,
      addresses.LINK_Address,
      addresses.USDT,
      addresses.USDC_Address,
    ],
    [
      "0x0000000000000000000000000000000000000348",
      "0x0000000000000000000000000000000000000348",
      "0x0000000000000000000000000000000000000348",
      "0x0000000000000000000000000000000000000348",
      "0x0000000000000000000000000000000000000348",
      "0x0000000000000000000000000000000000000348",
      "0x0000000000000000000000000000000000000348",
    ],
    [
      "0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA",
      "0x5133D67c38AFbdd02997c14Abd8d83676B4e309A",
      "0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA",
      "0x7A99092816C8BD5ec8ba229e3a6E6Da1E628E1F9",
      "0x8dF01C2eFed1404872b54a69f40a57FeC1545998",
      "0xefCA2bbe0EdD0E22b2e0d2F8248E99F4bEf4A7dB",
      "0xAADAa473C1bDF7317ec07c915680Af29DeBfdCb5",
    ]
  );
});

export { protocolConfig, accessController, priceOracle };
