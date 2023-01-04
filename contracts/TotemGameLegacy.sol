// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./abstract/TotemPauser.sol";
import "./abstract/TotemMetadata.sol";

contract TotemGameLegacy is Context, AccessControlEnumerable, TotemPauser, TotemMetadata {
    using Counters for Counters.Counter;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct LegacyRecord {
        address gameAddress;
        uint256 timestamp;
        string data;
    }

    struct GameRecordsStorage {
        mapping(address => Counters.Counter) counter;
        mapping(address => mapping(uint256 => uint256)) indexes;
    }

    LegacyRecord[] private _records;
    GameRecordsStorage private _gameRecords;

    constructor(string memory name, string memory symbol) TotemMetadata(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function totalSupply() public view returns (uint256) {
        return _records.length;
    }

    function balanceOf(address gameAddress) public view returns (uint256) {
        require(gameAddress != address(0), "invalid game address: must not be 0");
        return _gameRecords.counter[gameAddress].current();
    }

    function recordByIndex(uint256 index) public view returns (LegacyRecord memory record) {
        require(index < _records.length, "invalid record: index out of bounds");
        return _records[index];
    }

    function gameRecordByIndex(address gameAddress, uint256 index) public view returns (LegacyRecord memory record) {
        require(gameAddress != address(0), "invalid game address: must not be 0");
        require(index < _gameRecords.counter[gameAddress].current(), "invalid game record: index out of bounds");
        uint256 id = _gameRecords.indexes[gameAddress][index];
        return _records[id];
    }

    event GameLegacyRecord(address indexed gameAddress, uint256 indexed recordId);

    function create(address gameAddress, string calldata data) public whenNotPaused onlyRole(MANAGER_ROLE) {
        require(gameAddress != address(0), "invalid game address: must not be 0");
        uint256 recordId = _records.length;
        uint256 gameRecordId = _gameRecords.counter[gameAddress].current();
        _gameRecords.counter[gameAddress].increment();
        _records.push(LegacyRecord(gameAddress, block.timestamp, data));
        _gameRecords.indexes[gameAddress][gameRecordId] = recordId;
        emit GameLegacyRecord(gameAddress, recordId);
    }
}
