require("dotenv").config();
const crypto = require("node:crypto");
const { ethers } = require("hardhat");

async function run() {
    const { API_URL, PRIVATE_KEY } = process.env;
    const provider = new ethers.providers.JsonRpcProvider(API_URL);
    const account = new ethers.Wallet(PRIVATE_KEY, provider);
    // const tx = await ethers.provider.getTransaction('0xae0dcc1c9dab8b5d0042f2446a8cc4e546fbb7f9a00bb988df558a1d5d4d7709');
    // console.dir(tx);
    // console.log(`tx: gas price ${tx.gasPrice.toString()} gas limit ${tx.gasLimit.toString()}`);
    const gasPrice = await provider.getGasPrice();
    console.log(`gas price: ${gasPrice.toString()}`);
 }

run().then(()=> process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
})