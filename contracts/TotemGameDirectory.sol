// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./abstract/TotemPauser.sol";
import "./enums/EnumGameStatus.sol";

contract TotemGameDirectory is Context, AccessControlEnumerable, TotemPauser {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant GAME_MANAGER_ROLE = keccak256("GAMES_MANAGER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER_ROLE, _msgSender());
    }

    // Game data structure
    struct Game {
        address owner;
        string name;
        string author;
        string renderer_uri;
        string filters_uri;
        Status status;
    }

    // Games storage
    Game[] private _games;

    // Mapping owner to games counter
    mapping(address => Counters.Counter) private _ownerGamesCounter;

    // Mapping owner to games
    mapping(address => mapping(uint256 => uint256)) private _ownerGames;

    /**
     * Events
     */
    event GameCreate(uint256 indexed gameId, address indexed owner, address indexed createdBy);

    event GameUpdate(uint256 indexed gameId, address indexed updatedBy);

    event GameStatusChange(uint256 indexed gameId, Status indexed status);

    /**
     * Game
     */
    function totalSupply() public view returns (uint256) {
        return _games.length;
    }

    function ownerTotalSupply(address owner) public view returns (uint256) {
        require(owner != address(0), "invalid owner address");
        return _ownerGamesCounter[owner].current();
    }

    function createByManager(
        address owner,
        string calldata name,
        string calldata author,
        string calldata renderer_uri,
        string calldata filters_uri,
        Status status // by default it's 0, which is Status.Pending
    ) public whenNotPaused onlyRole(GAME_MANAGER_ROLE) {
        require(owner != address(0), "invalid owner address");
        require(uint8(status) < 4, "invalid status");
        _create(owner, name, author, renderer_uri, filters_uri, status);
    }

    function create(
        string calldata name,
        string calldata author,
        string calldata renderer_uri,
        string calldata filters_uri
    ) public whenNotPaused {
        _create(_msgSender(), name, author, renderer_uri, filters_uri, Status.Pending);
    }

    function _create(
        address owner,
        string calldata name,
        string calldata author,
        string calldata renderer_uri,
        string calldata filters_uri,
        Status status
    ) private {
        uint256 newGameId = _games.length;
        uint256 ownerIndex = _ownerGamesCounter[owner].current();
        _ownerGamesCounter[owner].increment();
        _games.push(Game(owner, name, author, renderer_uri, filters_uri, status));
        _ownerGames[owner][ownerIndex] = newGameId;
        emit GameCreate(newGameId, owner, _msgSender());
    }

    function update(
        uint256 index,
        string calldata name,
        string calldata author,
        string calldata renderer_uri,
        string calldata filters_uri
    ) public whenNotPaused {
        require(
            _msgSender() == _games[index].owner || hasRole(GAME_MANAGER_ROLE, _msgSender()),
            "forbidden, only owner or manager can update game information"
        );
        require(index < _games.length, "invalid game index, index out of bounds");
        _update(index, name, author, renderer_uri, filters_uri);
    }

    function _update(
        uint256 gameId,
        string calldata name,
        string calldata author,
        string calldata renderer_uri,
        string calldata filters_uri
    ) private {
        Game storage game = _games[gameId];
        game.name = name;
        game.author = author;
        game.renderer_uri = renderer_uri;
        game.filters_uri = filters_uri;
        // Change game status to "Pending" if updated by owner for additional review
        if (_msgSender() == game.owner) {
            game.status = Status.Pending;
            emit GameStatusChange(gameId, game.status);
        }
        emit GameUpdate(gameId, _msgSender());
    }

    function changeStatus(uint256 index, Status status) public whenNotPaused onlyRole(GAME_MANAGER_ROLE) {
        require(index < _games.length, "invalid game index, index out of bounds");
        require(uint8(status) < 4, "invalid status");
        _changeStatus(index, status);
    }

    function _changeStatus(uint256 gameId, Status status) private {
        Game storage game = _games[gameId];
        game.status = status;
        emit GameStatusChange(gameId, game.status);
    }

    function gameByIndex(
        uint256 index
    )
        public
        view
        returns (
            address owner,
            string memory name,
            string memory author,
            string memory renderer_uri,
            string memory filters_uri,
            Status status
        )
    {
        require(index < _games.length, "invalid game index, index out of bounds");
        Game storage game = _games[index];
        return (game.owner, game.name, game.author, game.renderer_uri, game.filters_uri, game.status);
    }

    function gameOfOwnerByIndex(
        address owner,
        uint256 index
    )
        public
        view
        returns (
            string memory name,
            string memory author,
            string memory renderer_uri,
            string memory filters_uri,
            Status status
        )
    {
        require(index < _ownerGamesCounter[owner].current(), "invalid owner game index, index out of bounds");
        Game storage game = _games[_ownerGames[owner][index]];
        return (game.name, game.author, game.renderer_uri, game.filters_uri, game.status);
    }
}
