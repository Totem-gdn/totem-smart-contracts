require("dotenv").config();
const crypto = require("node:crypto");
const { ethers } = require("hardhat");

async function list() {
    const { CONTRACT_ADDRESS, CONTRACT_NAME, API_URL, PRIVATE_KEY, TO } = process.env;
    console.log(`Loading contract: ${process.env.CONTRACT_NAME} on address: ${CONTRACT_ADDRESS}`);
    const provider = new ethers.providers.JsonRpcProvider(API_URL);
    const account = new ethers.Wallet(PRIVATE_KEY, provider);
    const contract = await ethers.getContractAt(CONTRACT_NAME, CONTRACT_ADDRESS, account);
    const to = TO;
    const balanceOf = await contract.balanceOf(to);
    console.log(`Balance of ${to}: ${balanceOf.toString()}`);
    for(let i = 0n; i < balanceOf.toBigInt(); i++) {
        const tokenId = await contract.tokenOfOwnerByIndex(to, i);
        console.log(`TokenId #${i}: ${tokenId.toString()}`);
        const tokenURI = await contract.tokenURI(tokenId);
        console.log(`TokenURI #${i}: ${tokenURI}`);
    }
}

list().then(()=> process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
})