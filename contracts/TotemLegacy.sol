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

    struct SystemRecordType {
        uint256 gameId;
        uint256 timestamp;
        string data;
    }

    struct AchievementRecordType {
        uint256 gameId;
        uint256 assetId;
        uint256 timestamp;
        string data;
    }

    SystemRecordType[] private _systemRecords;
    AchievementRecordType[] private _avatarAchievementRecords;
    AchievementRecordType[] private _itemAchievementRecords;
    AchievementRecordType[] private _gemAchievementRecords;

    // Mapping from game index to system records counter
    mapping(uint256 => Counters.Counter) private _gameSystemRecordsCounter;

    // Mapping from game index to mapping of the counter to system record index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameSystemRecords;

    // Mapping from game index to avatar achievements counter
    mapping(uint256 => Counters.Counter) private _gameAvatarAchievementsCounter;

    // Mapping from game index to item achievements counter
    mapping(uint256 => Counters.Counter) private _gameItemAchievementsCounter;

    // Mapping from game index to gem achievements counter
    mapping(uint256 => Counters.Counter) private _gameGemAchievementsCounter;

    // Mapping from game index to mapping of the counter to avatar achievement index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameAvatarAchievements;

    // Mapping from game index to mapping of the counter to item achievement index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameItemAchievements;

    // Mapping from game index to mapping of the counter to gem achievement index
    mapping(uint256 => mapping(uint256 => uint256)) private _gameGemAchievements;

    // Mapping from avatar index to counter
    mapping(uint256 => Counters.Counter) private _avatarAchievementsCounter;

    // Mapping from item index to counter
    mapping(uint256 => Counters.Counter) private _itemAchievementsCounter;

    // Mapping from gem index to counter
    mapping(uint256 => Counters.Counter) private _gemAchievementsCounter;

    // Mapping from avatar index to mapping of the counter to avatar achievement index
    mapping(uint256 => mapping(uint256 => uint256)) private _avatarAchievements;

    // Mapping from item index to mapping of the counter to avatar achievement index
    mapping(uint256 => mapping(uint256 => uint256)) private _itemAchievements;

    // Mapping from gem index to mapping of the counter to avatar achievement index
    mapping(uint256 => mapping(uint256 => uint256)) private _gemAchievements;

    /**
     * System records
     */
    event SystemRecord(uint256 indexed gameId, uint256 recordId);

    function systemRecordsTotalSupply() public view returns (uint256) {
        return _systemRecords.length;
    }

    function systemRecordsOfGameTotalSupply(uint256 gameId) public view returns (uint256) {
        return _gameSystemRecordsCounter[gameId].current();
    }

    function createSystemRecord(uint256 gameId, string calldata data) public whenNotPaused onlyRole(MANAGER_ROLE) {
        _createSystemRecord(gameId, data);
    }

    function _createSystemRecord(uint256 gameId, string calldata data) private {
        uint256 recordId = _systemRecords.length;
        _systemRecords.push(SystemRecordType(gameId, block.timestamp, data));
        uint256 gameRecordId = _gameSystemRecordsCounter[gameId].current();
        _gameSystemRecordsCounter[gameId].increment();
        _gameSystemRecords[gameId][gameRecordId] = recordId;
        emit SystemRecord(gameId, recordId);
    }

    function systemRecordByIndex(uint256 recordId)
        public
        view
        returns (
            uint256 gameId,
            uint256 timestamp,
            string memory data
        )
    {
        require(recordId < _systemRecords.length, "invalid system records index, index out of bounds");
        SystemRecordType storage record = _systemRecords[recordId];
        return (record.gameId, record.timestamp, record.data);
    }

    function systemRecordOfGameByIndex(uint256 gameId_, uint256 index)
        public
        view
        returns (
            uint256 gameId,
            uint256 timestamp,
            string memory data
        )
    {
        require(index < _gameSystemRecordsCounter[gameId].current(), "invalid game record index, index out of bounds");
        SystemRecordType storage record = _systemRecords[_gameSystemRecords[gameId_][index]];
        return (record.gameId, record.timestamp, record.data);
    }

    /**
     * Achievement records
     */
    event AchievementRecord(
        uint256 indexed assetId,
        bytes32 indexed assetType,
        uint256 indexed gameId,
        uint256 recordId
    );

    modifier validAssetType(bytes32 assetType) {
        require(assetType == AVATAR_ASSET || assetType == ITEM_ASSET || assetType == GEM_ASSET);
        _;
    }

    function achievementsTotalSupply(bytes32 assetType)
        public
        view
        validAssetType(assetType)
        returns (uint256 recordsCount)
    {
        if (assetType == AVATAR_ASSET) return _avatarAchievementRecords.length;
        if (assetType == ITEM_ASSET) return _itemAchievementRecords.length;
        if (assetType == GEM_ASSET) return _gemAchievementRecords.length;
    }

    function achievementsOfGameTotalSupply(uint256 gameId, bytes32 assetType)
        public
        view
        validAssetType(assetType)
        returns (uint256 recordsCount)
    {
        if (assetType == AVATAR_ASSET) return _gameAvatarAchievementsCounter[gameId].current();
        if (assetType == ITEM_ASSET) return _gameItemAchievementsCounter[gameId].current();
        if (assetType == GEM_ASSET) return _gameGemAchievementsCounter[gameId].current();
    }

    function achievementsOfAssetTotalSupply(uint256 assetId, bytes32 assetType)
        public
        view
        validAssetType(assetType)
        returns (uint256 recordsCount)
    {
        if (assetType == AVATAR_ASSET) return _avatarAchievementsCounter[assetId].current();
        if (assetType == ITEM_ASSET) return _itemAchievementsCounter[assetId].current();
        if (assetType == GEM_ASSET) return _gemAchievementsCounter[assetId].current();
    }

    function createAchievementRecord(
        uint256 gameId,
        uint256 assetId,
        bytes32 assetType,
        string calldata data
    ) public whenNotPaused onlyRole(MANAGER_ROLE) validAssetType(assetType) {
        _createAchievementRecord(gameId, assetId, assetType, data);
    }

    function _createAchievementRecord(
        uint256 gameId,
        uint256 assetId,
        bytes32 assetType,
        string calldata data
    ) private {
        AchievementRecordType memory record = AchievementRecordType(gameId, assetId, block.timestamp, data);
        uint256 recordId = 0;
        if (assetType == AVATAR_ASSET) {
            recordId = _avatarAchievementRecords.length;
            _avatarAchievementRecords.push(record);
            uint256 gameRecordId = _gameAvatarAchievementsCounter[gameId].current();
            _gameAvatarAchievementsCounter[gameId].increment();
            uint256 assetRecordId = _avatarAchievementsCounter[assetId].current();
            _avatarAchievementsCounter[assetId].increment();
            _gameAvatarAchievements[gameId][gameRecordId] = recordId;
            _avatarAchievements[assetId][assetRecordId] = recordId;
        }
        if (assetType == ITEM_ASSET) {
            recordId = _itemAchievementRecords.length;
            _itemAchievementRecords.push(record);
            uint256 gameRecordId = _gameItemAchievementsCounter[gameId].current();
            _gameItemAchievementsCounter[gameId].increment();
            uint256 assetRecordId = _itemAchievementsCounter[assetId].current();
            _itemAchievementsCounter[assetId].increment();
            _gameItemAchievements[gameId][gameRecordId] = recordId;
            _itemAchievements[assetId][assetRecordId] = recordId;
        }
        if (assetType == GEM_ASSET) {
            recordId = _gemAchievementRecords.length;
            _gemAchievementRecords.push(record);
            uint256 gameRecordId = _gameGemAchievementsCounter[gameId].current();
            _gameGemAchievementsCounter[gameId].increment();
            uint256 assetRecordId = _gemAchievementsCounter[assetId].current();
            _gemAchievementsCounter[assetId].increment();
            _gameGemAchievements[gameId][gameRecordId] = recordId;
            _gemAchievements[assetId][assetRecordId] = recordId;
        }
        emit AchievementRecord(assetId, assetType, gameId, recordId);
    }

    function achievementByIndex(uint256 index, bytes32 assetType)
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
            require(index < _avatarAchievementRecords.length, "invalid record index, index out of bounds");
            AchievementRecordType storage record = _avatarAchievementRecords[index];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == ITEM_ASSET) {
            require(index < _itemAchievementRecords.length, "invalid record index, index out of bounds");
            AchievementRecordType storage record = _itemAchievementRecords[index];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == GEM_ASSET) {
            require(index < _gemAchievementRecords.length, "invalid record index, index out of bounds");
            AchievementRecordType storage record = _gemAchievementRecords[index];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
    }

    function achievementOfGameByIndex(
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
            require(
                index < _gameAvatarAchievementsCounter[gameId_].current(),
                "invalid record index, index out of bounds"
            );
            AchievementRecordType storage record = _avatarAchievementRecords[_gameAvatarAchievements[gameId][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == ITEM_ASSET) {
            require(
                index < _gameItemAchievementsCounter[gameId_].current(),
                "invalid record index, index out of bounds"
            );
            AchievementRecordType storage record = _itemAchievementRecords[_gameItemAchievements[gameId][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == GEM_ASSET) {
            require(
                index < _gameGemAchievementsCounter[gameId_].current(),
                "invalid record index, index out of bounds"
            );
            AchievementRecordType storage record = _gemAchievementRecords[_gameGemAchievements[gameId][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
    }

    function achievementOfAssetByIndex(
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
            require(
                index < _avatarAchievementsCounter[assetId_].current(),
                "invalid record index, index out of bounds"
            );
            AchievementRecordType storage record = _avatarAchievementRecords[_avatarAchievements[assetId_][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == ITEM_ASSET) {
            require(index < _itemAchievementsCounter[assetId_].current(), "invalid record index, index out of bounds");
            AchievementRecordType storage record = _itemAchievementRecords[_itemAchievements[assetId_][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
        if (assetType == GEM_ASSET) {
            require(index < _gemAchievementsCounter[assetId_].current(), "invalid record index, index out of bounds");
            AchievementRecordType storage record = _gemAchievementRecords[_gemAchievements[assetId_][index]];
            return (record.gameId, record.assetId, record.timestamp, record.data);
        }
    }
}
