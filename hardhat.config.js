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
    format: 'json',
    path: './abi/json'
  }, {
    runOnCompile: true,
    clear: true,
    format: 'fullName',
    path: './abi/fullName'
  }]
};
