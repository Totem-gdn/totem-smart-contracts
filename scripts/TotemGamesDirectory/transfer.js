require("dotenv").config();
const hre = require("hardhat");

async function transfer() {
    const provider = await hre.ethers.provider;
    const signer = await hre.ethers.getSigner(process.env.PUBLIC_KEY);
    const contract = await hre.ethers.getContractAt(process.env.CONTRACT_NAME, process.env.CONTRACT_ADDRESS, signer);
    const games = await fetch(process.env.EXPLORER_API).then((res) => res.json());
    for (const game of games.reverse()) {
        console.group(game.general.name);
        while (true) {
            try {
                const gameRecord = {
                    name: game.general.name || "",
                    author: game.general.author || "",
                    renderer: game.connections.assetRenderer || "",
                    avatarFilter: (game.connections.dnaFilters && game.connections.dnaFilters.avatarFilter) || "",
                    itemFilter: (game.connections.dnaFilters && game.connections.dnaFilters.itemFilter) || "",
                    gemFilter: (game.connections.dnaFilters && game.connections.dnaFilters.gemFilter) || "",
                    website: game.connections.webpage || "",
                };
                const {maxFeePerGas, maxPriorityFeePerGas} = await provider.getFeeData();
                const gasLimit = await contract.estimateGas.create(game.owner, gameRecord, 1);
                const tx = await contract.create(game.owner, gameRecord, 1, {
                    gasLimit,
                    maxFeePerGas,
                    maxPriorityFeePerGas,
                });
                await tx.wait();
                console.log(`tx hash: ${tx.hash}`);
                break;
            } catch (ex) {
                console.error(`${ex.message}`);
            }
        }
        console.groupEnd();
    }
}

transfer()
    .catch((ex) => {
        console.error(ex);
        process.exit(1);
    })
    .finally(() => process.exit(0));
