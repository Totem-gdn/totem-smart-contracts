// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./abstract/TotemPauser.sol";
import "./abstract/TotemMetadata.sol";

contract TotemAssetLegacy is Context, AccessControlEnumerable, TotemPauser, TotemMetadata {
    using Counters for Counters.Counter;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct LegacyRecord {
        uint256 assetId;
        address gameAddress;
        uint256 timestamp;
        string data;
    }

    struct AssetRecordsStorage {
        mapping(uint256 => Counters.Counter) counter;
        mapping(uint256 => mapping(uint256 => uint256)) indexes;
    }

    LegacyRecord[] private _records;
    AssetRecordsStorage private _assetRecords;

    constructor(string memory name, string memory symbol) TotemMetadata(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function totalSupply() public view returns (uint256) {
        return _records.length;
    }

    function balanceOf(uint256 assetId) public view returns (uint256) {
        return _assetRecords.counter[assetId].current();
    }

    function recordByIndex(uint256 index) public view returns (LegacyRecord memory record) {
        require(index < _records.length, "invalid record: index out of bounds");
        return _records[index];
    }

    function assetRecordByIndex(uint256 assetId, uint256 index) public view returns (LegacyRecord memory record) {
        require(index < _assetRecords.counter[assetId].current(), "invalid asset record: index out of bounds");
        uint256 id = _assetRecords.indexes[assetId][index];
        return _records[id];
    }

    event AssetLegacyRecord(
        address indexed playerAddress,
        address indexed gameAddress,
        uint256 indexed assetId,
        uint256 recordId
    );

    function create(
        address playerAddress,
        address gameAddress,
        uint256 assetId,
        string calldata data
    ) public whenNotPaused onlyRole(MANAGER_ROLE) {
        require(playerAddress != address(0), "invalid player address: must not be 0");
        require(gameAddress != address(0), "invalid game address: must not be 0");
        uint256 recordId = _records.length;
        uint256 assetRecordId = _assetRecords.counter[assetId].current();
        _assetRecords.counter[assetId].increment();
        _records.push(LegacyRecord(assetId, gameAddress, block.timestamp, data));
        _assetRecords.indexes[assetId][assetRecordId] = recordId;
        emit AssetLegacyRecord(playerAddress, gameAddress, assetId, recordId);
    }
}
