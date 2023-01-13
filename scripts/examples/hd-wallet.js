require("dotenv").config();
const hre = require("hardhat");

// для того, чтобы создавать аккаунты для игр нужен либо seed, либо mnemonic
async function hdWallet() {
    const wallet = new hre.ethers.Wallet.fromMnemonic(
        "step job reform invest kidney short ripple spend reopen video verb mouse"
    );
    // const wallet = new hre.ethers.Wallet.createRandom();
    const words = wallet.mnemonic.phrase;
    console.log(`words: ${words}`);
    const seed = hre.ethers.utils.mnemonicToSeed(wallet.mnemonic.phrase);
    console.log(`seed: ${seed}`);
    console.log(`root pk: ${wallet.privateKey}`);
    let node = hre.ethers.utils.HDNode.fromSeed(seed);
    let account1 = node.derivePath("m/44'/60'/0'/0/0");
    let account2 = node.derivePath("m/44'/60'/0'/0/1");
    console.log(`account1 ${account1.address} pk ${account1.privateKey}`);
    console.log(`account2 ${account2.address} pk ${account2.privateKey}`);

    // from pk
    let node2 = hre.ethers.utils.HDNode.fromMnemonic(
        "step job reform invest kidney short ripple spend reopen video verb mouse"
    );
}

hdWallet().catch((ex) => {
    console.error(ex);
    process.exit(1);
});
