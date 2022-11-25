require("dotenv").config();
const crypto = require("node:crypto");
const {ethers} = require("hardhat");

async function mint() {
    const {CONTRACT_ADDRESS, CONTRACT_NAME, API_URL, PRIVATE_KEY, TO} = process.env;
    console.log(`Loading contract: ${process.env.CONTRACT_NAME} on address: ${CONTRACT_ADDRESS}`);
    const provider = new ethers.providers.JsonRpcProvider(API_URL);
    const account = new ethers.Wallet(PRIVATE_KEY, provider);
    const contract = await ethers.getContractAt(CONTRACT_NAME, CONTRACT_ADDRESS, account);
    const to = TO;
    const tokenURIBuffer = crypto.getRandomValues(new Uint8Array(2));
    const tokenURI = `0x` + Buffer.from(tokenURIBuffer).toString("hex");
    console.log(`Minting asset: to ${to}, uri ${tokenURI}`);
    const gasPrice = (await provider.getGasPrice()).mul(110n).div(100n);
    const gasLimit = await contract.estimateGas.safeMint(to, tokenURI);
    console.log(`gasPrice: ${gasPrice.toString()}, gasLimit: ${gasLimit.toString()}`);
    const txResponse = await contract.safeMint(to, tokenURI, {
        gasPrice,
        gasLimit,
    });
    console.log(`Minted at tx: ${txResponse.hash}`);
    const txReceipt = await ethers.provider.waitForTransaction(txResponse.hash);
    console.log(`Minted to : ${JSON.stringify(txReceipt)}`);
}

mint()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
