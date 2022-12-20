// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./abstract/TotemPauser.sol";
import "./abstract/TotemMetadata.sol";

contract TotemGamesDirectory is Context, AccessControlEnumerable, TotemPauser, TotemMetadata {
    using Counters for Counters.Counter;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    enum Status {
        Pending,
        Accepted,
        Rejected,
        Banned
    }

    struct Game {
        string name;
        string author;
        string renderer;
        string avatarFilter;
        string itemFilter;
        string gemFilter;
        string website;
        uint256 createdAt;
        uint256 updatedAt;
    }

    Game[] private _games;
    mapping(uint256 => address) private _gameOwner;
    mapping(uint256 => Status) private _gameStatus;
    mapping(address => uint256[]) private _ownerGames;

    constructor(string memory name, string memory symbol) TotemMetadata(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    modifier validRecordId(uint256 recordId) {
        require(recordId < _games.length, "invalid record index, index out of bounds");
        _;
    }

    modifier validStatus(Status status) {
        require(uint8(status) < 4, "invalid status");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _games.length;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _ownerGames[owner].length;
    }

    function recordByIndex(
        uint256 index
    ) public view validRecordId(index) returns (address owner, Game memory game, Status status) {
        return (_gameOwner[index], _games[index], _gameStatus[index]);
    }

    function ownerRecordByIndex(address owner, uint256 index) public view returns (uint256 recordId) {
        require(index < _ownerGames[owner].length, "invalid owner's record index, index out of bounds");
        return _ownerGames[owner][index];
    }

    event CreateGame(address indexed owner, uint256 indexed recordId);

    struct CreateGameData {
        string name;
        string author;
        string renderer;
        string avatarFilter;
        string itemFilter;
        string gemFilter;
        string website;
    }

    function create(
        address owner,
        CreateGameData calldata game,
        Status status
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validStatus(status) {
        require(owner != address(0), "invalid owner address");
        require(bytes(game.name).length > 0, "invalid name length");
        require(bytes(game.author).length > 0, "invalid author length");
        uint256 recordId = _games.length;
        _games.push(
            Game(
                game.name,
                game.author,
                game.renderer,
                game.avatarFilter,
                game.itemFilter,
                game.gemFilter,
                game.website,
                block.timestamp,
                block.timestamp
            )
        );
        _gameOwner[recordId] = owner;
        _gameStatus[recordId] = status;
        _ownerGames[owner].push(recordId);
        emit CreateGame(owner, recordId);
    }

    event UpdateGame(uint256 indexed recordId, string updatedField);

    function changeOwner(
        uint256 recordId,
        address newOwner
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        require(newOwner != address(0), "invalid new owner address");
        address prevOwner = _gameOwner[recordId];
        require(newOwner != prevOwner, "owner not changed");
        for (uint256 i = 0; i < _ownerGames[prevOwner].length; i++) {
            if (_ownerGames[prevOwner][i] == recordId) {
                _ownerGames[prevOwner][i] = _ownerGames[prevOwner][_ownerGames[prevOwner].length - 1];
                _ownerGames[prevOwner].pop();
                break;
            }
        }
        _ownerGames[newOwner].push(recordId);
        _gameOwner[recordId] = newOwner;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "owner");
    }

    function changeName(
        uint256 recordId,
        string calldata name
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        require(bytes(name).length > 0, "invalid name length");
        _games[recordId].name = name;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "name");
    }

    function changeAuthor(
        uint256 recordId,
        string calldata author
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        require(bytes(author).length > 0, "invalid author length");
        _games[recordId].author = author;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "author");
    }

    function changeRenderer(
        uint256 recordId,
        string calldata renderer
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        _games[recordId].renderer = renderer;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "renderer");
    }

    function changeAvatarFilter(
        uint256 recordId,
        string calldata avatarFilter
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        _games[recordId].avatarFilter = avatarFilter;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "avatarFilter");
    }

    function changeItemFilter(
        uint256 recordId,
        string calldata itemFilter
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        _games[recordId].itemFilter = itemFilter;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "itemFilter");
    }

    function changeGemFilter(
        uint256 recordId,
        string calldata gemFilter
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        _games[recordId].gemFilter = gemFilter;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "gemFilter");
    }

    function changeWebsite(
        uint256 recordId,
        string calldata website
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) {
        _games[recordId].website = website;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "website");
    }

    function changeStatus(
        uint256 recordId,
        Status status
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validRecordId(recordId) validStatus(status) {
        _gameStatus[recordId] = status;
        _games[recordId].updatedAt = block.timestamp;
        emit UpdateGame(recordId, "status");
    }
}
