import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const {RPC_URL1, RPC_URL2, RPC_URL3, PRIVATE_KEY, ETHERSCAN_API_KEY} = process.env;
const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: `${RPC_URL1}`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    arcTestnet: {
      url: `${RPC_URL2}`,
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 5042002,
    },
    liskSepolia: {
      url: `${RPC_URL3}`,
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 4202,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
   }
};

export default config;
