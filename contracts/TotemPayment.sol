// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./abstract/TotemPauser.sol";

contract TotemPayment is AccessControlEnumerable, Pausable, TotemPauser {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant ASSETS_MANAGER_ROLE = keccak256("ASSETS_MANAGER_ROLE");

    // Payment
    IERC20 private _paymentToken;
    address private _paymentWallet;

    // Assets
    bytes32 public TOTEM_ASSET_AVATAR = keccak256("TOTEMAVATAR");
    bytes32 public TOTEM_ASSET_ITEM = keccak256("TOTEMITEM");
    bytes32 public TOTEM_ASSET_GEM = keccak256("TOTEMGEM");

    struct Asset {
        bytes32 id;
        string symbol;
        string name;
        uint256 price;
    }

    mapping(bytes32 => Asset) private _assets;

    constructor(address token, address wallet) {
        require(token != address(0), "Invalid token address provided.");
        require(wallet != address(0), "Invalid wallet address provided.");

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ASSETS_MANAGER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());

        _paymentToken = IERC20(token);
        _paymentWallet = wallet;

        // Totem Avatar Asset
        _assets[TOTEM_ASSET_AVATAR] = Asset(TOTEM_ASSET_AVATAR, "TOTEMAVATAR", "Totem Avatar", 50);
        // Totem Item Asset
        _assets[TOTEM_ASSET_ITEM] = Asset(TOTEM_ASSET_ITEM, "TOTEMITEM", "Totem Item", 25);
        // Totem Gem Asset
        _assets[TOTEM_ASSET_GEM] = Asset(TOTEM_ASSET_GEM, "TOTEMGEM", "Totem Gem", 10);
    }

    // Change asset price
    event PriceChanged(address indexed account, bytes32 indexed assetId, uint256 oldPrice, uint256 newPrice);

    function setPrice(bytes32 assetId, uint256 price) public onlyRole(ASSETS_MANAGER_ROLE) returns (bool) {
        require(_assets[assetId].id == assetId, "Invalid asset id.");
        require(price > 0, "Price cannot be less than or equal to 0.");
        uint256 oldPrice = _assets[assetId].price;
        _assets[assetId].price = price;
        emit PriceChanged(_msgSender(), assetId, oldPrice, price);
        return true;
    }

    function listAssets() public view returns (Asset[3] memory) {
        return [_assets[TOTEM_ASSET_AVATAR], _assets[TOTEM_ASSET_ITEM], _assets[TOTEM_ASSET_GEM]];
    }

    // Purchase
    event MintAsset(address indexed buyer, bytes32 assetId);

    function buyAsset(bytes32 assetId) public whenNotPaused {
        require(_assets[assetId].id == assetId, "Invalid asset id.");
        require(
            _paymentToken.allowance(_msgSender(), address(this)) >= _assets[assetId].price,
            "Contract is not allowed to transfer tokens from buyer address."
        );
        // require(
        //     _paymentToken.balanceOf(_msgSender()) >= _assets[assetId].price,
        //     "Not enough tokens on buyer address."
        // );
        require(
            _paymentToken.transferFrom(_msgSender(), _paymentWallet, _assets[assetId].price),
            "Failed to transfer tokens from buyer wallet."
        );
        emit MintAsset(_msgSender(), assetId);
    }
}
