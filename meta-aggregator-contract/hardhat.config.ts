import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import 'dotenv/config';


const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 125,
          },
        },
      }
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
      base: `${process.env.DEPLOYER}`
    },
    executor: {
      default: 1
    },
    user: {
      default: 2
    },
    receiver: {
      default: 3
    },
  },
  networks: {
    base: {
      url: "https://base.llamarpc.com",
      chainId: 8453,
      saveDeployments: true,
      accounts: {
        mnemonic:
          `${process.env.MEMONIC}`,
      },
      verify: {
        etherscan: {
          apiUrl: 'https://api.basescan.org',
          apiKey: process.env.ETHERSCAN_KEY
        }
      },
    },
  },
  etherscan: {
    apiKey: {
      base: `${process.env.ETHERSCAN_KEY}`,
    },
  },
  sourcify: {
    enabled: true
  },
};

export default config;
