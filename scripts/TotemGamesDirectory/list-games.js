require("dotenv").config();
const hre = require("hardhat");

async function listGames() {
    const signer = await hre.ethers.getSigner(process.env.PUBLIC_KEY);
    const contract = await hre.ethers.getContractAt(process.env.CONTRACT_FACTORY, process.env.CONTRACT_ADDRESS, signer);
    const list = await contract.totalSupply();
    console.log(`total: ${list.toString()}`);
    for (let i = 0n; i < list.toBigInt(); i++) {
        const {gameAddress, game} = await contract.gameByIndex(i);
        console.dir({
            gameAddress: gameAddress,
            ownerAddress: game.ownerAddress,
            name: game.name,
            author: game.author,
            renderer: game.renderer,
            avatarFilter: game.avatarFilter,
            itemFilter: game.itemFilter,
            gemFilter: game.gemFilter,
            website: game.website,
            createdAt: game.createdAt.toString(),
            updatedAt: game.updatedAt.toString(),
            status: game.status,
        });
    }
}

listGames().catch((ex) => {
    console.error(ex);
    process.exit(1);
});
