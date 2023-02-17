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

Totem Avatar Contract   
[0x45C379E437bBC393cccA76Bacc41dCC04fe83D27](https://mumbai.polygonscan.com/address/0x45C379E437bBC393cccA76Bacc41dCC04fe83D27)

Totem Item Contract   
[0x68FcC37845D0085493375461fB0eB0c0039c725D](https://mumbai.polygonscan.com/address/0x68FcC37845D0085493375461fB0eB0c0039c725D)

Totem Gem Contract   
[0xE1FbBF5Ff7e50522855119712e4805aE0259D36E](https://mumbai.polygonscan.com/address/0xE1FbBF5Ff7e50522855119712e4805aE0259D36E)

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


## Production contracts

Totem Avatar Contract   
[0x11dBDbF2e6D262c2fe7e73ace1A60c6862dC14dE](https://mumbai.polygonscan.com/address/0x11dBDbF2e6D262c2fe7e73ace1A60c6862dC14dE)

Totem Item Contract   
[0xEc9C96eF9b90a950057EDbe40B42385f3b1cE78C](https://mumbai.polygonscan.com/address/0xEc9C96eF9b90a950057EDbe40B42385f3b1cE78C)

Totem Gem Contract   
[0x981AE243e701bDbA0f6be830921c4F662ba90cE4](https://mumbai.polygonscan.com/address/0x981AE243e701bDbA0f6be830921c4F662ba90cE4)

Avatar Legacy Contract  
[0x76bc452b3f20F356C1FCdF61f2144E05CD90584d](https://mumbai.polygonscan.com/address/0x76bc452b3f20F356C1FCdF61f2144E05CD90584d)

Item Legacy Contract  
[0xdDa0ceF69A8b7894523B823bdEBB9fcBe86fF7c0](https://mumbai.polygonscan.com/address/0xdDa0ceF69A8b7894523B823bdEBB9fcBe86fF7c0)

Gem Legacy Contract  
[0xb1255917C82A71e49DF1f36E22C16A92eE429B82](https://mumbai.polygonscan.com/address/0xb1255917C82A71e49DF1f36E22C16A92eE429B82)

Game Legacy Contract  
[0x92dCDE5012405daCFa9332E0d75C07B62826A708](https://mumbai.polygonscan.com/address/0x92dCDE5012405daCFa9332E0d75C07B62826A708)

Games Directory Contract  
[0xF0Be39F816638Bd96e42a4219201dCfE18a33eef](https://mumbai.polygonscan.com/address/0xF0Be39F816638Bd96e42a4219201dCfE18a33eef)
