# Totem Smart Contracts

This repository stores all Totem Smart Contracts.

## Compile contracts

```bash
npm run compile
```

This command compiles all contracts from `contracts` directory.  
Compilation also creates two types of Contract ABI: `human-readable (fullName)` and `json`, that can be found in `abi`
directory.

## Run tests

```bash
npm test
```

## Deploy contracts

Run script with `hardhat run` command. Provide `--network` from `hardhat.config.js`.

```bash
export PRIVATE_KEY=0x_your_private_key
export CONTRACT_FACTORY=contract_factory
export CONTRACT_ARGS='["Name","Symbol"]'
npx hardhat run scripts/deploy.js --network mumbai
```

After contract deployment you can find all deployment info in directory:  
`deployments/{date}/{network}/{contract_factory}/{contract_args[1]}_{contract_address}`  
Example:

```
deployments/Thu-Jan-01-1970/mumbai/TotemGamesDirectory/[TEST]TotemGamesDirectory_0x0
```

## Verify contract on etherscan

```bash
npx hardhat verify CONTRACT_ADDRESS --network mumbai
```

## Development contracts

Avatar Legacy Contract  
[0xc59693685E51b8C7b50be2F9446660d604109acF](https://mumbai.polygonscan.com/address/0xc59693685E51b8C7b50be2F9446660d604109acF)

Item Legacy Contract  
[0x8d9B893D28500e6FA692b9711dBacE3a8e1fA721](https://mumbai.polygonscan.com/address/0x8d9B893D28500e6FA692b9711dBacE3a8e1fA721)

Gem Legacy Contract  
[0x266A4cDC8b29213f75F5dc4061d3fa42136fDbfD](https://mumbai.polygonscan.com/address/0x266A4cDC8b29213f75F5dc4061d3fa42136fDbfD)

Game Legacy Contract  
[0x69C53E195FA60D4F08c98eD6F0Bb717b619DA254](https://mumbai.polygonscan.com/address/0x69C53E195FA60D4F08c98eD6F0Bb717b619DA254)

Games Directory Contract  
[0x56c07105cA580F6F3D4B0e2c2033CF3E9Cb215c8](https://mumbai.polygonscan.com/address/0x56c07105cA580F6F3D4B0e2c2033CF3E9Cb215c8)
