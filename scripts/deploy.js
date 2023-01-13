require("dotenv").config();
const hre = require("hardhat");
const {open, mkdir} = require("node:fs/promises");
const {join} = require("node:path");

function contractUrl(address) {
    if (hre.network.name === "mumbai") {
        return `https://mumbai.polygonscan.com/address/${address}`;
    }
    if (hre.network.name === "mainnet") {
        return `https://polygonscan.com/address/${address}`;
    }
    return address;
}

async function deploy() {
    if (hre.network.name === "mainnet") {
        throw new Error(`mainnet unavailable right now`);
    }
    console.log(`creating contract factory: ${process.env.CONTRACT_FACTORY}(${process.env.CONTRACT_ARGS})`);
    const args = JSON.parse(process.env.CONTRACT_ARGS) || []; // json array
    console.log(`deploying contract...`);
    let contract, txReceipt;
    while (true) {
        try {
            const contractFactory = await hre.ethers.getContractFactory(process.env.CONTRACT_FACTORY);
            contract = await contractFactory.deploy(...args);
            await contract.deployed();
            txReceipt = await hre.ethers.provider.getTransaction(contract.deployTransaction.hash);
            console.log(`deployed at ${contractUrl(contract.address)}`);
            break;
        } catch (ex) {
            console.error(ex.message);
        }
    }
    if (process.env.DEBUG_LOGS) {
        console.dir(contract);
        console.dir(txReceipt);
    }
    const filepath = join(
        process.cwd(),
        "deployments",
        new Date().toDateString().replace(/\s/g, "-"),
        hre.network.name,
        process.env.CONTRACT_FACTORY
    );
    await mkdir(filepath, {recursive: true});
    const fd = await open(join(filepath, `${args[1]}_${contract.address}`), "w+");
    const ws = fd.createWriteStream({encoding: "utf-8"});
    ws.write(
        JSON.stringify(
            {
                args,
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
    console.error(err.message, err.stack);
    process.exit(1);
});
