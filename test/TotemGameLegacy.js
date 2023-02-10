require("@nomicfoundation/hardhat-chai-matchers");
const {expect} = require("chai");
const {ethers} = require("hardhat");
const {BigNumber} = require("ethers");

describe("Totem game legacy contract", function () {
    let totemGameLegacies;
    let gameAddress;
    let emptyGameAddress;

    before(async function () {
        const contractFactory = await ethers.getContractFactory("TotemGameLegacy");
        totemGameLegacies = await contractFactory.deploy("Totem Game Legacies", "TotemGameLegacies");
        gameAddress = ethers.Wallet.createRandom().address;
        emptyGameAddress = ethers.Wallet.createRandom().address;
    });

    it("Should deploy successfully", async function () {
        expect(await totemGameLegacies.name()).to.equal("Totem Game Legacies");
        expect(await totemGameLegacies.symbol()).to.equal("TotemGameLegacies");
    });

    it("Should add new legacy record to game", async function () {
        const recordId = BigNumber.from("0");
        const gameData = JSON.stringify({index: "0"});

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("0"));
        expect(await totemGameLegacies.balanceOf(gameAddress)).to.equal(BigNumber.from("0"));
        expect(await totemGameLegacies.balanceOf(emptyGameAddress)).to.equal(BigNumber.from("0"));

        await expect(totemGameLegacies.create(gameAddress, gameData))
            .to.emit(totemGameLegacies, "GameLegacyRecord")
            .withArgs(gameAddress, recordId);

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemGameLegacies.balanceOf(gameAddress)).to.equal(BigNumber.from("1"));
        expect(await totemGameLegacies.balanceOf(emptyGameAddress)).to.equal(BigNumber.from("0"));
    });

    it("Should return record by index", async function () {
        const recordId = BigNumber.from("1");
        const gameData = JSON.stringify({index: "1"});

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("1"));
        expect(await totemGameLegacies.balanceOf(gameAddress)).to.equal(BigNumber.from("1"));

        await expect(totemGameLegacies.create(gameAddress, gameData))
            .to.emit(totemGameLegacies, "GameLegacyRecord")
            .withArgs(gameAddress, recordId);

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("2"));
        expect(await totemGameLegacies.balanceOf(gameAddress)).to.equal(BigNumber.from("2"));

        const assetRecord = await totemGameLegacies.recordByIndex(recordId);
        expect(assetRecord.gameAddress).to.equal(gameAddress);
        expect(assetRecord.timestamp.toNumber()).to.lessThanOrEqual(Date.now());
        expect(assetRecord.data).to.equal(gameData);
    });

    it("Should return game record by index", async function () {
        const recordId = BigNumber.from("1");
        const gameData = JSON.stringify({index: "1"});

        expect(await totemGameLegacies.totalSupply()).to.equal(BigNumber.from("2"));
        expect(await totemGameLegacies.balanceOf(gameAddress)).to.equal(BigNumber.from("2"));

        const assetRecord = await totemGameLegacies.gameRecordByIndex(gameAddress, recordId);
        expect(assetRecord.gameAddress).to.equal(gameAddress);
        expect(assetRecord.timestamp.toNumber()).to.lessThanOrEqual(Date.now());
        expect(assetRecord.data).to.equal(gameData);
    });

    it("Should return error index out of bounds", async function () {
        const totalSupply = BigNumber.from("2");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemGameLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemGameLegacies.recordByIndex(invalidRecordId)).to.be.revertedWith(
            "invalid record: index out of bounds"
        );
    });

    it("Should return error index out of bounds for game", async function () {
        const totalSupply = BigNumber.from("2");
        const invalidRecordId = BigNumber.from("9999");

        expect(await totemGameLegacies.totalSupply()).to.equal(totalSupply);
        await expect(totemGameLegacies.gameRecordByIndex(gameAddress, invalidRecordId)).to.be.revertedWith(
            "invalid game record: index out of bounds"
        );
    });
});
