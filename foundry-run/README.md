# Sample Foundry Project

## Follow the steps below to deploy your contract

### SETUP
```shell
forge init project-name
cd project-name
```

### COMPILE
Go to /src/ and replace the demo contract .sol with yours
Go to /script and replace the demo script .t.sol with yours

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
Go to /hardhat.config.ts and make the following changes including networks and etherscan

```shell
require("dotenv").config();
const {SEPOLIA_RPC_URL, SEPOLIA_PRIVATE_KEY, ETHERSCAN_API_KEY} = process.env;
```

```shell
networks: {
    sepolia: {
      url: `${SEPOLIA_RPC_URL}`,
      accounts: [`0x${SEPOLIA_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
   }
```
Add your .env file in your project root

```shell
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/...
SEPOLIA_PRIVATE_KEY=...
ETHERSCAN_API_KEY=...
```

```shell
npm install dotenv
npx hardhat ignition deploy ignition/modules/Owner.ts --network sepolia --verify
```
