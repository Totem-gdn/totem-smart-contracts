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
        uint256 gameId;
        uint256 timestamp;
        string data;
    }

    LegacyRecord[] private _records;
    mapping(uint256 => Counters.Counter) private _assetCounter;
    mapping(uint256 => mapping(uint256 => uint256)) private _assetRecords;

    constructor(string memory name, string memory symbol) TotemMetadata(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function totalSupply() public view returns (uint256) {
        return _records.length;
    }

    function balanceOf(uint256 assetId) public view returns (uint256) {
        return _assetCounter[assetId].current();
    }

    function recordByIndex(
        uint256 index
    ) public view returns (uint256 _gameId, uint256 _assetId, uint256 _timestamp, string memory _data) {
        require(index < _records.length, "invalid record index, index out of bounds");
        return (_records[index].gameId, _records[index].assetId, _records[index].timestamp, _records[index].data);
    }

    function assetRecordByIndex(
        uint256 assetId,
        uint256 index
    ) public view returns (uint256 _gameId, uint256 _assetId, uint256 _timestamp, string memory _data) {
        require(index < _assetCounter[assetId].current(), "invalid asset record index, index out of bounds");
        uint256 id = _assetRecords[assetId][index];
        return (_records[id].gameId, _records[id].assetId, _records[id].timestamp, _records[id].data);
    }

    event AssetLegacyRecord(uint256 indexed assetId, uint256 indexed gameId, uint256 indexed recordId);

    function create(uint256 assetId, uint256 gameId, string calldata data) public whenNotPaused onlyRole(MANAGER_ROLE) {
        uint256 recordId = _records.length;
        uint256 assetRecordId = _assetCounter[assetId].current();
        _assetCounter[assetId].increment();
        _records.push(LegacyRecord(assetId, gameId, block.timestamp, data));
        _assetRecords[assetId][assetRecordId] = recordId;
        emit AssetLegacyRecord(assetId, gameId, recordId);
    }
}
