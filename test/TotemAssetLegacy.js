require("@nomicfoundation/hardhat-chai-matchers");
const {expect} = require("chai");
const {ethers} = require("hardhat");
const {BigNumber} = require("ethers");

describe("Totem asset legacy contract", function () {
    let totemAssetLegacies;
    let playerAddress;
    let gameAddress;

    before(async function () {
        const contractFactory = await ethers.getContractFactory("TotemAssetLegacy");
        totemAssetLegacies = await contractFactory.deploy("Totem Asset Legacies", "TotemAssetLegacies");
        playerAddress = ethers.Wallet.createRandom().address;
        gameAddress = ethers.Wallet.createRandom().address;
    });

    it("Should deploy successfully", async function () {
        expect(await totemAssetLegacies.name()).to.equal("Totem Asset Legacies");
        expect(await totemAssetLegacies.symbol()).to.equal("TotemAssetLegacies");
    });

    it("Should add new legacy record to asset", async function () {
        const assetId = BigNumber.from("0");
        const assetData = JSON.stringify({index: "0"});
        const emptyAssetId = BigNumber.from("9999");

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("0"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("0"));
        expect(await totemAssetLegacies.balanceOf(emptyAssetId)).to.equal(BigNumber.from("0"));

        const newRecordId = BigNumber.from("0");
        await expect(await totemAssetLegacies.create(playerAddress, gameAddress, assetId, assetData))
            .to.emit(totemAssetLegacies, "AssetLegacyRecord")
            .withArgs(playerAddress, gameAddress, assetId, newRecordId);

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("1"));
        expect(await totemAssetLegacies.balanceOf(emptyAssetId)).to.equal(BigNumber.from("0"));
    });

    it("Should receive record by index", async function () {
        const recordId = BigNumber.from("1");
        const assetId = BigNumber.from("0");
        const assetData = JSON.stringify({index: "1"});

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("1"));

        await expect(await totemAssetLegacies.create(playerAddress, gameAddress, assetId, assetData))
            .to.emit(totemAssetLegacies, "AssetLegacyRecord")
            .withArgs(playerAddress, gameAddress, assetId, recordId);

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("2"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("2"));

        const assetRecord = await totemAssetLegacies.recordByIndex(recordId);
        expect(assetRecord.assetId).to.equal(assetId);
        expect(assetRecord.gameAddress).to.equal(gameAddress);
        expect(assetRecord.timestamp.toNumber()).to.lessThanOrEqual(Date.now());
        expect(assetRecord.data).to.equal(assetData);
    });

    it("Should return asset record by index", async function () {
        const assetId = BigNumber.from("0");
        const index = BigNumber.from("1");
        const assetData = JSON.stringify({index: "1"});

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("2"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("2"));

        const assetRecord = await totemAssetLegacies.assetRecordByIndex(assetId, index);
        expect(assetRecord.assetId).to.equal(assetId);
        expect(assetRecord.gameAddress).to.equal(gameAddress);
        expect(assetRecord.timestamp.toNumber()).to.lessThanOrEqual(Date.now());
        expect(assetRecord.data).to.equal(assetData);
    });

    it("Should return error index out of bounds", async function () {
        const totalSupply = BigNumber.from("2");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemAssetLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemAssetLegacies.recordByIndex(invalidRecordId)).to.be.revertedWith(
            "invalid record: index out of bounds"
        );
    });

    it("Should return error index out of bounds for asset", async function () {
        const totalSupply = BigNumber.from("2");
        const assetId = BigNumber.from("0");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemAssetLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemAssetLegacies.assetRecordByIndex(assetId, invalidRecordId)).to.be.revertedWith(
            "invalid asset record: index out of bounds"
        );
    });
});
