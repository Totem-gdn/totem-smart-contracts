require("dotenv").config();
const hre = require("hardhat");

async function listGames() {
    const signer = await hre.ethers.getSigner(process.env.PUBLIC_KEY);
    const contract = await hre.ethers.getContractAt(process.env.CONTRACT_NAME, process.env.CONTRACT_ADDRESS, signer);
    const list = await contract.totalSupply();
    console.log(list.toBigInt());
    for (let i = 0n; i < list.toBigInt(); i++) {
        const {owner, game, status} = await contract.recordByIndex(i);
        console.dir({
            recordId: i,
            owner,
            game,
            status,
        });
    }
}

listGames().catch((ex) => {
    console.error(ex);
    process.exit(1);
});
