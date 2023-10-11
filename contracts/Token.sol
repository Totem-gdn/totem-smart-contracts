// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;
/// @author Owlen

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TotemToken is ERC20, Pausable, AccessControl {
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1E9 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TRANSFER_ROLE, msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function grantTransferPermission(
        address account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(TRANSFER_ROLE, account);
    }

    function revokeTransferPermission(
        address account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(TRANSFER_ROLE, account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (paused()) {
            require(
                hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to),
                "Token: Token Paused and either sender nor recipient do not have a transfer permission"
            );
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
