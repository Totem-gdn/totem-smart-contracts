require("dotenv").config();
const crypto = require("node:crypto");
const { ethers } = require("hardhat");
const { hexDataSlice } = require("ethers/lib/utils");

async function run() {
    const { CONTRACT_ADDRESS, CONTRACT_NAME, API_URL, PRIVATE_KEY, TO } = process.env;
    console.log(`Loading contract: ${process.env.CONTRACT_NAME} on address: ${CONTRACT_ADDRESS}`);
    const provider = new ethers.providers.JsonRpcProvider(API_URL);
    const account = new ethers.Wallet(PRIVATE_KEY, provider);
    const contract = await ethers.getContractAt(CONTRACT_NAME, CONTRACT_ADDRESS, account);
    const tx = await ethers.provider.getTransaction('0xae0dcc1c9dab8b5d0042f2446a8cc4e546fbb7f9a00bb988df558a1d5d4d7709');
    console.dir(tx);
    console.log(`tx: gas price ${tx.gasPrice.toString()} gas limit ${tx.gasLimit.toString()}`);
    const gasPrice = await provider.getGasPrice();
    console.log(`gas price: ${gasPrice.toString()}`);
    tx.gasPrice = gasPrice.mul(110n).div(100n);
    tx.maxPriorityFeePerGas = tx.gasPrice;
    tx.maxFeePerGas = tx.gasPrice;
    console.dir(tx);
    console.dir(ethers.utils.defaultAbiCoder.decode(['string','string'],hexDataSlice(tx.data, 4)));
}

run().then(()=> process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
})