require("@nomicfoundation/hardhat-chai-matchers");
const {expect} = require("chai");
const hre = require("hardhat");

describe("Totem asset contract", function () {
    const contractName = "[TEST] Totem Asset";
    const contractSymbol = "TestTotemAsset";
    let totemAsset;
    let signerAddress;
    let minterAddress;
    let playerAddress;
    let tokenCounter = hre.ethers.BigNumber.from("0");
    const tokenURI_1 = "token-uri-1";
    const tokenURI_2 = "token-uri-2";

    before(async function () {
        const contractFactory = await hre.ethers.getContractFactory("TotemAsset");
        totemAsset = await contractFactory.deploy(contractName, contractSymbol);
        signerAddress = await hre.ethers.provider.getSigner(0).getAddress();
        minterAddress = hre.ethers.Wallet.createRandom().address;
        playerAddress = hre.ethers.Wallet.createRandom().address;
    });

    it("Should deploy successfully", async function () {
        expect(await totemAsset.name()).to.equal(contractName);
        expect(await totemAsset.symbol()).to.equal(contractSymbol);
    });

    it("Should mint asset", async function () {
        expect(await totemAsset.totalSupply()).to.equal(tokenCounter);
        await expect(totemAsset["safeMint(address,string)"](playerAddress, tokenURI_1))
            .to.emit(totemAsset, "Transfer")
            .withArgs(hre.ethers.constants.AddressZero, playerAddress, tokenCounter);
        tokenCounter = tokenCounter.add(1);
    });

    it("Should mint asset with data", async function () {
        const data = Buffer.from("test-data", "utf8");
        expect(await totemAsset.totalSupply()).to.equal(hre.ethers.BigNumber.from("1"));
        await expect(totemAsset["safeMint(address,string,bytes)"](playerAddress, tokenURI_2, data))
            .to.emit(totemAsset, "Transfer")
            .withArgs(hre.ethers.constants.AddressZero, playerAddress, tokenCounter);
        tokenCounter = tokenCounter.add(1);
    });

    it("Should grant minter role", async function () {
        const minterRole = await totemAsset.MINTER_ROLE();
        expect(minterRole).to.equal(hre.ethers.utils.keccak256(Buffer.from("MINTER_ROLE", "utf8")));
        await expect(totemAsset.grantRole(minterRole, minterAddress))
            .to.emit(totemAsset, "RoleGranted")
            .withArgs(minterRole, minterAddress, signerAddress);
    });

    it("Should receive token by index", async function () {
        expect(await totemAsset.tokenByIndex(hre.ethers.BigNumber.from("0"))).to.equal(hre.ethers.BigNumber.from("0"));
    });

    it("Should receive token uri by index", async function () {
        expect(await totemAsset.tokenURI(hre.ethers.BigNumber.from("0"))).to.equal(tokenURI_1);
    });
});
