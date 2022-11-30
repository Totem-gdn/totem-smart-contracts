require("@nomicfoundation/hardhat-chai-matchers");
const {expect} = require("chai");
const {ethers} = require("hardhat");
const {BigNumber} = require("ethers");

describe("Totem game legacy contract", function () {
    let totemGameLegacies;

    before(async function () {
        const contractFactory = await ethers.getContractFactory("TotemGameLegacy");
        totemGameLegacies = await contractFactory.deploy("Totem Game Legacies", "TotemGameLegacies");
    });

    it("Should deploy successfully", async function () {
        expect(await totemGameLegacies.name()).to.equal("Totem Game Legacies");
        expect(await totemGameLegacies.symbol()).to.equal("TotemGameLegacies");
    });

    it("Should add new legacy record to game", async function () {
        const recordId = BigNumber.from("0");
        const gameId = BigNumber.from("0");
        const gameData = JSON.stringify({index: "0"});
        const emptyGameId = BigNumber.from("9999");

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("0"));
        expect(await totemGameLegacies.balanceOf(gameId)).to.equal(BigNumber.from("0"));
        expect(await totemGameLegacies.balanceOf(emptyGameId)).to.equal(BigNumber.from("0"));

        await expect(await totemGameLegacies.create(gameId, gameData))
            .to.emit(totemGameLegacies, "GameLegacyRecord")
            .withArgs(gameId, recordId);

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemGameLegacies.balanceOf(gameId)).to.equal(BigNumber.from("1"));
        expect(await totemGameLegacies.balanceOf(emptyGameId)).to.equal(BigNumber.from("0"));
    });

    it("Should return record by index", async function () {
        const recordId = BigNumber.from("1");
        const gameId = BigNumber.from("0");
        const gameData = JSON.stringify({index: "1"});

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemGameLegacies.balanceOf(gameId)).to.equal(BigNumber.from("1"));

        await expect(await totemGameLegacies.create(gameId, gameData))
            .to.emit(totemGameLegacies, "GameLegacyRecord")
            .withArgs(gameId, recordId);

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("2"));
        expect(await totemGameLegacies.balanceOf(gameId)).to.equal(BigNumber.from("2"));

        const assetRecord = await totemGameLegacies.recordByIndex(recordId);
        expect(assetRecord.recordId).to.equal(recordId);
        expect(assetRecord.record.gameId).to.equal(gameId);
        expect(assetRecord.record.timestamp.toNumber()).to.lessThanOrEqual(Date.now());
        expect(assetRecord.record.data).to.equal(gameData);
    });

    it("Should return game record by index", async function () {
        const recordId = BigNumber.from("1");
        const gameId = BigNumber.from("0");
        const gameData = JSON.stringify({index: "1"});

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("2"));
        expect(await totemGameLegacies.balanceOf(gameId)).to.equal(BigNumber.from("2"));

        const assetRecord = await totemGameLegacies.gameRecordByIndex(gameId, recordId);
        expect(assetRecord.recordId).to.equal(recordId);
        expect(assetRecord.record.gameId).to.equal(gameId);
        expect(assetRecord.record.timestamp.toNumber()).to.lessThanOrEqual(Date.now());
        expect(assetRecord.record.data).to.equal(gameData);
    });

    it("Should return error index out of bounds", async function () {
        const totalSupply = BigNumber.from("2");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemGameLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemGameLegacies.recordByIndex(invalidRecordId)).to.be.revertedWith(
            "invalid record index, index out of bounds"
        );
    });

    it("Should return error index out of bounds for game", async function () {
        const totalSupply = BigNumber.from("2");
        const gameId = BigNumber.from("0");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemGameLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemGameLegacies.gameRecordByIndex(gameId, invalidRecordId)).to.be.revertedWith(
            "invalid game record index, index out of bounds"
        );
    });
});
