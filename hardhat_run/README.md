# Sample Hardhat Project

## Follow the steps below to deploy your contract

### SETUP
Create your project directory and move into it
```shell
npm init -y
npm install --save-dev hardhat@hh2
npx hardhat init
```

### COMPILE
Go to /contracts/ and replace the demo contract .sol with yours
Go to /ignition/modules and replace the demo script .ts or .sol with yours

```shell
npx hardhat compile
```

#### If there are compilation errors, just follow the prompt to install missing files. It's likely one of the following:
```shell
npm install --save-dev typescript
npm install --save-dev ts-node 
npm install --save-dev "@nomicfoundation/hardhat-chai-matchers@^2.1.0" "@nomicfoundation/hardhat-ethers@^3.1.0" "@nomicfoundation/hardhat-ignition-ethers@^0.15.14" "@nomicfoundation/hardhat-network-helpers@^1.1.0" "@nomicfoundation/hardhat-verify@^2.1.0" "@typechain/ethers-v6@^0.5.0" "@typechain/hardhat@^9.0.0" "@types/chai@^4.2.0" "@types/mocha@>=9.1.0" "@types/node@>=20.0.0" "chai@^4.2.0" "ethers@^6.14.0" "hardhat-gas-reporter@^2.3.0" "solidity-coverage@^0.8.1" "typechain@^8.3.0"
npm install --save-dev "@nomicfoundation/hardhat-ignition@^0.15.16" "@nomicfoundation/ignition-core@^0.15.15"
```

### DEPLOY
Ensure your have appropriate tokens in your wallet. Get free tokens from:
```shell
https://faucet.circle.com/
https://faucets.chain.link/
https://sepolia-bridge.lisk.com/
```

Go to /hardhat.config.ts and make the following changes including networks and etherscan
```shell
require("dotenv").config();
const {RPC_URL1, RPC_URL2, RPC_URL3, PRIVATE_KEY, ETHERSCAN_API_KEY} = process.env;
```

```shell
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
```

Add your .env file in your project root
```shell
RPC_URL1=https://eth-sepolia.g.alchemy.com/v2/... 
RPC_URL2=https://rpc.testnet.arc.network 
RPC_URL3=https://rpc.sepolia-api.lisk.com
SEPOLIA_PRIVATE_KEY=...
ETHERSCAN_API_KEY=...

```

```shell
npm install dotenv
npx hardhat ignition deploy ignition/modules/Owner.ts --network sepolia --verify
npx hardhat ignition deploy ignition/modules/Owner.ts --network arcTestnet --verify
npx hardhat ignition deploy ignition/modules/Owner.ts --network liskSepolia --verify
```

If verification fails, you can visit he network's explorer to verify manually.
#### Verified Arc Address - 0x81AeC0B87CAa631365B0AC0B628A84afdf6f1Fe9
#### Verified Lisk Address - 0xabc8Fb2C87F7C9a247d7286d14987820594FdDFe
