require("dotenv").config();
const {writeFileSync} = require("node:fs");
const hre = require("hardhat");

async function transfer() {
    const provider = await hre.ethers.provider;
    const signer = await hre.ethers.getSigner(process.env.PUBLIC_KEY);
    const contract = await hre.ethers.getContractAt(process.env.CONTRACT_FACTORY, process.env.CONTRACT_ADDRESS, signer);
    const explorerUrl = new URL(process.env.EXPLORER_API);
    explorerUrl.searchParams.set("list", "latest");
    let games = [];
    let found = 0;
    let page = 1;
    do {
        explorerUrl.searchParams.set("page", page.toString(10));
        found = 0;
        const res = await fetch(explorerUrl.toString()).then((res) => res.json());
        games.push(...res);
        found = res.length;
        page++;
    } while (found !== 0);
    console.log(`games count: ${games.length}`);
    const json = [];
    for (const game of games) {
        console.group(game.general.name);
        const wallet = hre.ethers.Wallet.createRandom();
        console.log(`mnemonic: ${wallet.mnemonic.phrase}`);
        console.log(`privateKey: ${wallet.privateKey}`);
        while (true) {
            try {
                const gameRecord = {
                    ownerAddress: game.owner,
                    name: game.general.name || "",
                    author: game.general.author || "",
                    renderer: game.connections.assetRenderer || "",
                    avatarFilter: (game.connections.dnaFilters && game.connections.dnaFilters.avatarFilter) || "",
                    itemFilter: (game.connections.dnaFilters && game.connections.dnaFilters.itemFilter) || "",
                    gemFilter: (game.connections.dnaFilters && game.connections.dnaFilters.gemFilter) || "",
                    website: game.connections.webpage || "",
                    status: 2,
                };
                const {maxFeePerGas, maxPriorityFeePerGas} = await provider.getFeeData();
                const gasLimit = await contract.estimateGas.create(wallet.address, gameRecord);
                const tx = await contract.create(wallet.address, gameRecord, {
                    gasLimit,
                    maxFeePerGas,
                    maxPriorityFeePerGas,
                });
                await tx.wait();
                console.log(`tx hash: ${tx.hash}`);
                json.push({
                    name: game.general.name,
                    mnemonic: wallet.mnemonic.phrase,
                    privateKey: wallet.privateKey,
                    address: wallet.address,
                });
                break;
            } catch (ex) {
                console.error(`${ex.message}`);
            }
        }
        console.groupEnd();
    }
    writeFileSync("games.txt", JSON.stringify(json, null, "\t"), {encoding: "utf-8"});
}

transfer()
    .catch((ex) => {
        console.error(ex);
        process.exit(1);
    })
    .finally(() => process.exit(0));
