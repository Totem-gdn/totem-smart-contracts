require("@nomicfoundation/hardhat-chai-matchers");
const {expect} = require("chai");
const {ethers} = require("hardhat");
const {BigNumber} = require("ethers");

describe("Totem asset legacy contract", function () {
    let totemAssetLegacies;

    before(async function () {
        const contractFactory = await ethers.getContractFactory("TotemAssetLegacy");
        totemAssetLegacies = await contractFactory.deploy("Totem Asset Legacies", "TotemAssetLegacies");
    });

    it("Should deploy successfully", async function () {
        expect(await totemAssetLegacies.name()).to.equal("Totem Asset Legacies");
        expect(await totemAssetLegacies.symbol()).to.equal("TotemAssetLegacies");
    });

    it("Should add new legacy record to asset", async function () {
        const assetId = BigNumber.from("0");
        const gameId = BigNumber.from("0");
        const assetData = JSON.stringify({index: "0"});
        const emptyAssetId = BigNumber.from("9999");

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("0"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("0"));
        expect(await totemAssetLegacies.balanceOf(emptyAssetId)).to.equal(BigNumber.from("0"));

        const newRecordId = BigNumber.from("0");
        await expect(await totemAssetLegacies.create(assetId, gameId, assetData))
            .to.emit(totemAssetLegacies, "AssetLegacyRecord")
            .withArgs(assetId, gameId, newRecordId);

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("1"));
        expect(await totemAssetLegacies.balanceOf(emptyAssetId)).to.equal(BigNumber.from("0"));
    });

    it("Should receive asset record by index", async function () {
        const assetId = BigNumber.from("0");
        const gameId = BigNumber.from("0");
        const assetData = JSON.stringify({index: "1"});
        const newRecordId = BigNumber.from("1");

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("1"));

        await expect(await totemAssetLegacies.create(assetId, gameId, assetData))
            .to.emit(totemAssetLegacies, "AssetLegacyRecord")
            .withArgs(assetId, gameId, newRecordId);

        expect(await totemAssetLegacies.totalSupply()).to.equal(BigNumber.from("2"));
        expect(await totemAssetLegacies.balanceOf(assetId)).to.equal(BigNumber.from("2"));

        const record = await totemAssetLegacies.recordByIndex(newRecordId);
        expect(record._assetId).to.equal(assetId);
        expect(record._gameId).to.equal(gameId);
        expect(record._timestamp.toNumber()).to.lessThanOrEqual(Date.now());
        expect(record._data).to.equal(assetData);
    });

    it("Should return error index out of bounds", async function () {
        const totalSupply = BigNumber.from("2");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemAssetLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemAssetLegacies.recordByIndex(invalidRecordId)).to.be.revertedWith(
            "invalid record index, index out of bounds"
        );
    });

    it("Should return error index out of bounds for asset", async function () {
        const totalSupply = BigNumber.from("2");
        const assetId = BigNumber.from("0");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemAssetLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemAssetLegacies.assetRecordByIndex(assetId, invalidRecordId)).to.be.revertedWith(
            "invalid asset record index, index out of bounds"
        );
    });
});