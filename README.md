# totem-smart-contracts

## Compile contracts

```bash
npm run compile
```

This command compiles all contracts from `contracts` directory. Compilation also creates two types of Contract ABI: `human-readable` and `json`, that can be found in `abi` directory.


## Run tests

```bash
npm test
```

## Deploy contracts

Run script with `hardhat run` command. Provide `--network` from `hardhat.config.js`.

```bash
npx hardhat run scripts/deploy.js --network mumbai
```

## Verify contract on etherscan

```bash
npx hardhat verify CONTRACT_ADDRESS --network mumbai
```

