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
        Undefined,
        Pending,
        Accepted,
        Rejected,
        Banned
    }

    struct Game {
        address ownerAddress;
        string name;
        string author;
        string renderer;
        string avatarFilter;
        string itemFilter;
        string gemFilter;
        string website;
        uint256 createdAt;
        uint256 updatedAt;
        Status status;
    }

    Counters.Counter private _counter;
    mapping(address => Game) private _games;
    mapping(uint256 => address) private _indexes;

    constructor(string memory name, string memory symbol) TotemMetadata(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    function totalSupply() public view returns (uint256) {
        return _counter.current();
    }

    function gameByIndex(uint256 index) public view returns (address gameAddress, Game memory game) {
        require(index < _counter.current(), "invalid game record: index out of bounds");
        gameAddress = _indexes[index];
        game = _games[gameAddress];
        return (gameAddress, game);
    }

    function gameByAddress(address gameAddress) public view returns (Game memory game) {
        require(_games[gameAddress].status != Status.Undefined, "invalid game record: not found");
        return _games[gameAddress];
    }

    event CreateGame(address indexed gameAddress, address indexed ownerAddress);

    struct CreateGameData {
        address ownerAddress;
        string name;
        string author;
        string renderer;
        string avatarFilter;
        string itemFilter;
        string gemFilter;
        string website;
        Status status;
    }

    function create(address gameAddress, CreateGameData calldata game) public whenNotPaused onlyRole(MANAGER_ROLE) {
        require(gameAddress != address(0), "invalid game address");
        require(game.ownerAddress != address(0), "invalid owner address");
        require(_games[gameAddress].status == Status.Undefined, "game already exists");
        require(bytes(game.name).length > 0, "invalid name length");
        require(bytes(game.author).length > 0, "invalid author length");
        require(uint8(game.status) > 0 && uint8(game.status) < 5, "invalid status");

        uint256 index = _counter.current();
        _counter.increment();

        _games[gameAddress] = Game(
            game.ownerAddress,
            game.name,
            game.author,
            game.renderer,
            game.avatarFilter,
            game.itemFilter,
            game.gemFilter,
            game.website,
            block.timestamp,
            block.timestamp,
            game.status
        );
        _indexes[index] = gameAddress;

        emit CreateGame(gameAddress, game.ownerAddress);
    }

    event UpdateGame(address indexed gameAddress);

    struct UpdateGameData {
        address ownerAddress;
        string name;
        string author;
        string renderer;
        string avatarFilter;
        string itemFilter;
        string gemFilter;
        string website;
        Status status;
    }

    function update(address gameAddress, UpdateGameData calldata game) public whenNotPaused onlyRole(MANAGER_ROLE) {
        require(_games[gameAddress].status != Status.Undefined, "invalid game record: not found");
        require(game.ownerAddress != address(0), "invalid owner address");
        require(bytes(game.name).length > 0, "invalid name length");
        require(bytes(game.author).length > 0, "invalid author length");
        require(uint8(game.status) > 0 && uint8(game.status) < 5, "invalid status");

        _games[gameAddress].ownerAddress = game.ownerAddress;
        _games[gameAddress].name = game.name;
        _games[gameAddress].author = game.author;
        _games[gameAddress].renderer = game.renderer;
        _games[gameAddress].avatarFilter = game.avatarFilter;
        _games[gameAddress].itemFilter = game.itemFilter;
        _games[gameAddress].gemFilter = game.gemFilter;
        _games[gameAddress].website = game.website;
        _games[gameAddress].updatedAt = block.timestamp;
        _games[gameAddress].status = game.status;

        emit UpdateGame(gameAddress);
    }
}
