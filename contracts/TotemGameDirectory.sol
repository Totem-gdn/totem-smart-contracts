// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./abstract/TotemPauser.sol";
import "./abstract/TotemMetadata.sol";

contract TotemGameDirectory is Context, AccessControlEnumerable, TotemPauser, TotemMetadata {
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
        string assetFilter;
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

    modifier validGameId(uint256 gameId) {
        require(gameId < _games.length, "invalid game index, index out of bounds");
        _;
    }

    modifier validStatus(Status status) {
        require(uint8(status) < 4, "invalid game status");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _games.length;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _ownerGames[owner].length;
    }

    function gameByIndex(
        uint256 index
    ) public view validGameId(index) returns (uint256 gameId, address owner, Game memory game, Status status) {
        return (index, _gameOwner[index], _games[index], _gameStatus[index]);
    }

    function ownerGameByIndex(
        address gameOwner,
        uint256 index
    ) public view returns (uint256 gameId, address owner, Game memory game, Status status) {
        require(index < _ownerGames[gameOwner].length, "invalid owner game index, index out of bounds");
        uint256 id = _ownerGames[gameOwner][index];
        return (id, _gameOwner[id], _games[id], _gameStatus[id]);
    }

    event CreateGame(address indexed owner, uint256 indexed gameId);

    struct CreateGameData {
        string name;
        string author;
        string renderer;
        string avatarFilter;
        string assetFilter;
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
        uint256 gameId = _games.length;
        _games.push(
            Game(
                game.name,
                game.author,
                game.renderer,
                game.avatarFilter,
                game.assetFilter,
                game.gemFilter,
                game.website,
                block.timestamp,
                block.timestamp
            )
        );
        _gameOwner[gameId] = owner;
        _gameStatus[gameId] = status;
        _ownerGames[owner].push(gameId);
        emit CreateGame(owner, gameId);
    }

    event UpdateGame(uint256 indexed gameId, string updatedField);

    function changeOwner(
        uint256 gameId,
        address newOwner
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        require(newOwner != address(0), "invalid new owner address");
        address prevOwner = _gameOwner[gameId];
        require(newOwner != prevOwner, "owner not changed");
        for (uint256 i = 0; i < _ownerGames[prevOwner].length; i++) {
            if (_ownerGames[prevOwner][i] == gameId) {
                _ownerGames[prevOwner][i] = _ownerGames[prevOwner][_ownerGames[prevOwner].length - 1];
                _ownerGames[prevOwner].pop();
                break;
            }
        }
        _ownerGames[newOwner].push(gameId);
        _gameOwner[gameId] = newOwner;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "owner");
    }

    function changeName(
        uint256 gameId,
        string calldata name
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        require(bytes(name).length > 0, "invalid name length");
        _games[gameId].name = name;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "name");
    }

    function changeAuthor(
        uint256 gameId,
        string calldata author
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        require(bytes(author).length > 0, "invalid author length");
        _games[gameId].author = author;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "author");
    }

    function changeRenderer(
        uint256 gameId,
        string calldata renderer
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        _games[gameId].renderer = renderer;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "renderer");
    }

    function changeAvatarFilter(
        uint256 gameId,
        string calldata avatarFilter
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        _games[gameId].avatarFilter = avatarFilter;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "avatarFilter");
    }

    function changeAssetFilter(
        uint256 gameId,
        string calldata assetFilter
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        _games[gameId].assetFilter = assetFilter;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "assetFilter");
    }

    function changeGemFilter(
        uint256 gameId,
        string calldata gemFilter
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        _games[gameId].gemFilter = gemFilter;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "gemFilter");
    }

    function changeWebsite(
        uint256 gameId,
        string calldata website
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) {
        _games[gameId].website = website;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "website");
    }

    function changeStatus(
        uint256 gameId,
        Status status
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validGameId(gameId) validStatus(status) {
        _gameStatus[gameId] = status;
        _games[gameId].updatedAt = block.timestamp;
        emit UpdateGame(gameId, "status");
    }
}
