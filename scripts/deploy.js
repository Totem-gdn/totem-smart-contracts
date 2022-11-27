require("dotenv").config();
const {ethers, network} = require("hardhat");
const {open, mkdir} = require("node:fs/promises");
const {join} = require("node:path");

function contractUrl(address) {
    if (network.name === "mumbai") {
        return `https://mumbai.polygonscan.com/address/${address}`;
    }
    if (network.name === "mainnet") {
        return `https://polygonscan.com/address/${address}`;
    }
    return address;
}

async function deploy() {
    if (network.name === "mainnet") {
        throw new Error(`mainnet unavailable right now`);
    }
    console.log(`creating contract factory: ${process.env.CONTRACT_NAME}`);
    const contractFactory = await ethers.getContractFactory(process.env.CONTRACT_NAME);
    const args = JSON.parse(process.env.CONTRACT_ARGS) || []; // json array
    console.log(`deploying contract...`);
    const contract = await contractFactory.deploy(...args);
    await contract.deployed();
    const txReceipt = await ethers.provider.getTransaction(contract.deployTransaction.hash);
    console.log(`deployed at ${contractUrl(contract.address)}`);
    if (process.env.DEBUG_LOGS) {
        console.dir(contract);
        console.dir(txReceipt);
    }
    const filepath = join(process.cwd(), "deployments", network.name, process.env.CONTRACT_NAME);
    await mkdir(filepath, {recursive: true});
    const fd = await open(join(filepath, contract.address), "w+");
    const ws = fd.createWriteStream({encoding: "utf-8"});
    ws.write(
        JSON.stringify(
            {
                url: contractUrl(contract.address),
                address: contract.address,
                tx: {
                    hash: txReceipt.hash,
                },
                block: {
                    number: txReceipt.blockNumber,
                    hash: txReceipt.blockHash,
                },
            },
            null,
            "\t"
        )
    );
    ws.close();
    fd.close();
}

deploy().catch((err) => {
    console.error(err);
    process.exit(1);
});
