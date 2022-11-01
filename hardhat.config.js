/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("hardhat-abi-exporter");
module.exports = {
  solidity: "0.8.9",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    mumbai: {
      url: 'https://matic-mumbai.chainstacklabs.com',
      accounts: [process.env.PRIVATE_KEY],
    }
  },
  abiExporter: [{
    runOnCompile: true,
    clear: true,
    pretty: true,
    path: './abi/human-readable'
  }, {
    runOnCompile: true,
    clear: true,
    pretty: false,
    path: './abi/json'
  }]
};
