// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./abstract/TotemPauser.sol";

contract TotemLegacy is Context, AccessControlEnumerable, TotemPauser {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Asset types
    bytes32 public constant AVATAR_ASSET = keccak256("AVATAR_ASSET");
    bytes32 public constant ITEM_ASSET = keccak256("ITEM_ASSET");
    bytes32 public constant GEM_ASSET = keccak256("GEM_ASSET");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    struct GameLegacy {
        uint256 gameId;
        uint256 timestamp;
        string data;
    }

    struct AssetLegacy {
        uint256 gameId;
        uint256 assetId;
        uint256 timestamp;
        string data;
    }

    GameLegacy[] private _gameLegacies;
    AssetLegacy[] private _avatarLegacies;
    AssetLegacy[] private _itemLegacies;
    AssetLegacy[] private _gemLegacies;

    // Mapping from game index to game legacy records counter
    mapping(uint256 => Counters.Counter) private _gameRecordsCounter;

    // Mapping from game index to mapping of the counter to game legacy record index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameRecords;

    // Mapping from game index to avatar legacy counter
    mapping(uint256 => Counters.Counter) private _gameAvatarRecordsCounter;

    // Mapping from game index to item legacy counter
    mapping(uint256 => Counters.Counter) private _gameItemRecordsCounter;

    // Mapping from game index to gem legacy counter
    mapping(uint256 => Counters.Counter) private _gameGemRecordsCounter;

    // Mapping from game index to mapping of the counter to avatar legacy index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameAvatarRecords;

    // Mapping from game index to mapping of the counter to item legacy index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameItemRecords;

    // Mapping from game index to mapping of the counter to gem legacy index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameGemRecords;

    // Mapping from avatar index to counter
    mapping(uint256 => Counters.Counter) private _avatarRecordsCounter;

    // Mapping from item index to counter
    mapping(uint256 => Counters.Counter) private _itemRecordsCounter;

    // Mapping from gem index to counter
    mapping(uint256 => Counters.Counter) private _gemRecordsCounter;

    // Mapping from avatar index to mapping of the counter to avatar legacy index
    mapping(uint256 => mapping(uint256 => uint256)) private _avatarRecords;

    // Mapping from item index to mapping of the counter to avatar legacy index
    mapping(uint256 => mapping(uint256 => uint256)) private _itemRecords;

    // Mapping from gem index to mapping of the counter to avatar legacy index
    mapping(uint256 => mapping(uint256 => uint256)) private _gemRecords;

    /**
     * System records
     */
    event GameLegacyRecord(uint256 indexed gameId, uint256 recordId);

    function gameLegaciesTotalSupply() public view returns (uint256) {
        return _gameLegacies.length;
    }

    function gameLegaciesOfGameTotalSupply(uint256 gameId) public view returns (uint256) {
        return _gameRecordsCounter[gameId].current();
    }

    function createGameLegacy(uint256 gameId, string calldata data) public whenNotPaused onlyRole(MANAGER_ROLE) {
        _createGameLegacy(gameId, data);
    }

    function _createGameLegacy(uint256 gameId, string calldata data) private {
        uint256 recordId = _gameLegacies.length;
        _gameLegacies.push(GameLegacy(gameId, block.timestamp, data));
        uint256 gameRecordId = _gameRecordsCounter[gameId].current();
        _gameRecordsCounter[gameId].increment();
        _gameRecords[gameId][gameRecordId] = recordId;
        emit GameLegacyRecord(gameId, recordId);
    }

    function gameLegacyByIndex(uint256 recordId)
        public
        view
        returns (
            uint256 gameId,
            uint256 timestamp,
            string memory data
        )
    {
        require(recordId < _gameLegacies.length, "invalid record index, index out of bounds");
        GameLegacy storage record = _gameLegacies[recordId];
        return (record.gameId, record.timestamp, record.data);
    }

    function gameLegacyOfGameByIndex(uint256 gameId_, uint256 index)
        public
        view
        returns (
            uint256 gameId,
            uint256 timestamp,
            string memory data
        )
    {
        require(index < _gameRecordsCounter[gameId].current(), "invalid record index, index out of bounds");
        GameLegacy storage record = _gameLegacies[_gameRecords[gameId_][index]];
        return (record.gameId, record.timestamp, record.data);
    }

    /**
     * Achievement records
     */
    event AssetLegacyRecord(
        uint256 indexed assetId,
        bytes32 indexed assetType,
        uint256 indexed gameId,
        uint256 recordId
    );

    modifier validAssetType(bytes32 assetType) {
        require(assetType == AVATAR_ASSET || assetType == ITEM_ASSET || assetType == GEM_ASSET);
        _;
    }

    function assetLegaciesTotalSupply(bytes32 assetType)
        public
        view
        validAssetType(assetType)
        returns (uint256 recordsCount)
    {
        if (assetType == AVATAR_ASSET) return _avatarLegacies.length;
        if (assetType == ITEM_ASSET) return _itemLegacies.length;
        if (assetType == GEM_ASSET) return _gemLegacies.length;
    }

    function assetLegaciesOfGameTotalSupply(uint256 gameId, bytes32 assetType)
        public
        view
        validAssetType(assetType)
        returns (uint256 recordsCount)
    {
        if (assetType == AVATAR_ASSET) return _gameAvatarRecordsCounter[gameId].current();
        if (assetType == ITEM_ASSET) return _gameItemRecordsCounter[gameId].current();
        if (assetType == GEM_ASSET) return _gameGemRecordsCounter[gameId].current();
    }

    function assetLegaciesOfAssetTotalSupply(uint256 assetId, bytes32 assetType)
        public
        view
        validAssetType(assetType)
        returns (uint256 recordsCount)
    {
        if (assetType == AVATAR_ASSET) return _avatarRecordsCounter[assetId].current();
        if (assetType == ITEM_ASSET) return _itemRecordsCounter[assetId].current();
        if (assetType == GEM_ASSET) return _gemRecordsCounter[assetId].current();
    }

    function createAssetLegacy(
        uint256 gameId,
        uint256 assetId,
        bytes32 assetType,
        string calldata data
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validAssetType(assetType) {
        _createAssetLegacy(gameId, assetId, assetType, data);
    }

    function _createAssetLegacy(
        uint256 gameId,
        uint256 assetId,
        bytes32 assetType,
        string calldata data
    ) private {
        AssetLegacy memory record = AssetLegacy(gameId, assetId, block.timestamp, data);
        uint256 recordId = 0;
        if (assetType == AVATAR_ASSET) {
            recordId = _avatarLegacies.length;
            _avatarLegacies.push(record);
            uint256 gameRecordId = _gameAvatarRecordsCounter[gameId].current();
            _gameAvatarRecordsCounter[gameId].increment();
            uint256 assetRecordId = _avatarRecordsCounter[assetId].current();
            _avatarRecordsCounter[assetId].increment();
            _gameAvatarRecords[gameId][gameRecordId] = recordId;
            _avatarRecords[assetId][assetRecordId] = recordId;
        }
        if (assetType == ITEM_ASSET) {
            recordId = _itemLegacies.length;
            _itemLegacies.push(record);
            uint256 gameRecordId = _gameItemRecordsCounter[gameId].current();
            _gameItemRecordsCounter[gameId].increment();
            uint256 assetRecordId = _itemRecordsCounter[assetId].current();
            _itemRecordsCounter[assetId].increment();
            _gameItemRecords[gameId][gameRecordId] = recordId;
            _itemRecords[assetId][assetRecordId] = recordId;
        }
        if (assetType == GEM_ASSET) {
            recordId = _gemLegacies.length;
            _gemLegacies.push(record);
            uint256 gameRecordId = _gameGemRecordsCounter[gameId].current();
            _gameGemRecordsCounter[gameId].increment();
            uint256 assetRecordId = _gemRecordsCounter[assetId].current();
            _gemRecordsCounter[assetId].increment();
            _gameGemRecords[gameId][gameRecordId] = recordId;
            _gemRecords[assetId][assetRecordId] = recordId;
        }
        emit AssetLegacyRecord(assetId, assetType, gameId, recordId);
    }

    function assetLegacyByIndex(uint256 index, bytes32 assetType)
        public
        view
        validAssetType(assetType)
        returns (
            uint256 gameId,
            uint256 assetId,
            uint256 timestamp,
            string memory data
        )
    {
        if (assetType == AVATAR_ASSET) {
            require(index < _avatarLegacies.length, "invalid record index, index out of bounds");
            AssetLegacy storage record = _avatarLegacies[index];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == ITEM_ASSET) {
            require(index < _itemLegacies.length, "invalid record index, index out of bounds");
            AssetLegacy storage record = _itemLegacies[index];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == GEM_ASSET) {
            require(index < _gemLegacies.length, "invalid record index, index out of bounds");
            AssetLegacy storage record = _gemLegacies[index];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
    }

    function assetLegacyOfGameByIndex(
        uint256 gameId_,
        uint256 index,
        bytes32 assetType
    )
        public
        view
        validAssetType(assetType)
        returns (
            uint256 gameId,
            uint256 assetId,
            uint256 timestamp,
            string memory data
        )
    {
        if (assetType == AVATAR_ASSET) {
            require(index < _gameAvatarRecordsCounter[gameId_].current(), "invalid record index, index out of bounds");
            AssetLegacy storage record = _avatarLegacies[_gameAvatarRecords[gameId][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == ITEM_ASSET) {
            require(index < _gameItemRecordsCounter[gameId_].current(), "invalid record index, index out of bounds");
            AssetLegacy storage record = _itemLegacies[_gameItemRecords[gameId][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == GEM_ASSET) {
            require(index < _gameGemRecordsCounter[gameId_].current(), "invalid record index, index out of bounds");
            AssetLegacy storage record = _gemLegacies[_gameGemRecords[gameId][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
    }

    function assetLegacyOfAssetByIndex(
        uint256 assetId_,
        uint256 index,
        bytes32 assetType
    )
        public
        view
        validAssetType(assetType)
        returns (
            uint256 gameId,
            uint256 assetId,
            uint256 timestamp,
            string memory data
        )
    {
        if (assetType == AVATAR_ASSET) {
            require(index < _avatarRecordsCounter[assetId_].current(), "invalid record index, index out of bounds");
            AssetLegacy storage record = _avatarLegacies[_avatarRecords[assetId_][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == ITEM_ASSET) {
            require(index < _itemRecordsCounter[assetId_].current(), "invalid record index, index out of bounds");
            AssetLegacy storage record = _itemLegacies[_itemRecords[assetId_][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == GEM_ASSET) {
            require(index < _gemRecordsCounter[assetId_].current(), "invalid record index, index out of bounds");
            AssetLegacy storage record = _gemLegacies[_gemRecords[assetId_][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
    }
}
