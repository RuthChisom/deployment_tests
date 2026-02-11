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

### DEPLOY

Add your .env file in your project root
```shell
RPC_URL1=https://eth-sepolia.g.alchemy.com/v2/... 
RPC_URL2=https://rpc.testnet.arc.network 
RPC_URL3=https://rpc.sepolia-api.lisk.com 
PRIVATE_KEY=0x...
```

```shell
forge script script/Owner.s.sol --broadcast --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

If verification fails, you can visit he network's explorer to verify manually.
#### Verified Arc Address - 0xA9Eaf8E76966b60e9aB63C74a42605E84adF9EcE
#### Verified Lisk Address - 0xc07b379108d1C818f7b98a173B45ED59bc666439