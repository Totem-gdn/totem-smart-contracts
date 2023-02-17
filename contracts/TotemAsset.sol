// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./abstract/TotemPauser.sol";

contract TotemAsset is
    Context,
    AccessControlEnumerable,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Pausable,
    ERC721Burnable,
    TotemPauser
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TOKEN_URI_ROLE = keccak256("TOKEN_URI_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(TOKEN_URI_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
    }

    function safeMint(address to, string calldata uri) public onlyRole(MINTER_ROLE) {
        _safeMint(to, uri, "");
    }

    function safeMint(address to, string calldata uri, bytes calldata data) public onlyRole(MINTER_ROLE) {
        _safeMint(to, uri, data);
    }

    function _safeMint(address to, string memory uri, bytes memory data) internal {
        uint256 tokenId = totalSupply();
        super._safeMint(to, tokenId, data);
        _setTokenURI(tokenId, uri);
    }

    function burn(uint256 tokenId) public override onlyRole(BURNER_ROLE) {
        super.burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyRole(TOKEN_URI_ROLE) {
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
