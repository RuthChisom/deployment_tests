# Sample Foundry Project

## Follow the steps below to deploy your contract

### SETUP
```shell
forge init project-name
cd project-name
```

### COMPILE
Go to /src/ and replace the demo contract .sol with yours
Go to /script and replace the demo script .s.sol with yours
Go to /test and remove the demo test

```shell
forge build
```

If you get "Error: solc exited with signal:", add this to your foundry.toml
```shell
solc-version = "0.8.20"
```

### DEPLOY
Ensure your have appropriate tokens in your wallet. Get free tokens from:
```shell
https://cloud.google.com/application/web3/faucet
https://faucet.circle.com/
https://faucets.chain.link/
https://sepolia-bridge.lisk.com/
```

Add your .env file in your project root
```shell
RPC_URL1=https://eth-sepolia.g.alchemy.com/v2/... 
RPC_URL2=https://rpc.testnet.arc.network 
RPC_URL3=https://rpc.sepolia-api.lisk.com 
PRIVATE_KEY=0x...
```

```shell
source .env
forge script script/Owner.s.sol --broadcast --rpc-url $RPC_URL1 --private-key $PRIVATE_KEY
forge script script/Owner.s.sol --broadcast --rpc-url $RPC_URL2 --private-key $PRIVATE_KEY
forge script script/Owner.s.sol --broadcast --rpc-url $RPC_URL3 --private-key $PRIVATE_KEY
```

If verification fails, you can visit he network's explorer to verify manually.
#### Verified Arc Address - 0xA9Eaf8E76966b60e9aB63C74a42605E84adF9EcE
#### Verified Lisk Address - 0xc07b379108d1C818f7b98a173B45ED59bc666439