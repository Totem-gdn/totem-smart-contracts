/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-abi-exporter");
require("hardhat-gas-reporter");
module.exports = {
    solidity: "0.8.9",
    defaultNetwork: "hardhat",
    etherscan: {
        apiKey: {
            polygonMumbai: process.env.ETHERSCAN_APIKEY,
        },
    },
    networks: {
        hardhat: {},
        mumbai: {
            url: "https://matic-mumbai.chainstacklabs.com",
            accounts: [process.env.PRIVATE_KEY],
        },
    },
    abiExporter: [
        {
            runOnCompile: true,
            clear: true,
            format: "json",
            path: "./abi/json",
        },
        {
            runOnCompile: true,
            clear: true,
            format: "fullName",
            path: "./abi/fullName",
        },
    ],
    gasReporter: {
        enable: true,
    },
};
