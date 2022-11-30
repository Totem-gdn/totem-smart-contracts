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
        uint256 gameId;
        uint256 timestamp;
        string data;
    }

    LegacyRecord[] private _records;
    mapping(uint256 => Counters.Counter) private _gameCounter;
    mapping(uint256 => mapping(uint256 => uint256)) private _gameRecords;

    constructor(string memory name, string memory symbol) TotemMetadata(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function totalSupply() public view returns (uint256) {
        return _records.length;
    }

    function balanceOf(uint256 gameId) public view returns (uint256) {
        return _gameCounter[gameId].current();
    }

    function recordByIndex(uint256 index) public view returns (uint256 recordId, LegacyRecord memory record) {
        require(index < _records.length, "invalid record index, index out of bounds");
        return (index, _records[index]);
    }

    function gameRecordByIndex(
        uint256 gameId,
        uint256 index
    ) public view returns (uint256 recordId, LegacyRecord memory record) {
        require(index < _gameCounter[gameId].current(), "invalid game record index, index out of bounds");
        uint256 id = _gameRecords[gameId][index];
        return (id, _records[id]);
    }

    event GameLegacyRecord(uint256 indexed gameId, uint256 indexed recordId);

    function create(uint256 gameId, string calldata data) public whenNotPaused onlyRole(MANAGER_ROLE) {
        uint256 recordId = _records.length;
        uint256 gameRecordId = _gameCounter[gameId].current();
        _gameCounter[gameId].increment();
        _records.push(LegacyRecord(gameId, block.timestamp, data));
        _gameRecords[gameId][gameRecordId] = recordId;
        emit GameLegacyRecord(gameId, recordId);
    }
}
