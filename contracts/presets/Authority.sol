// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Pausable} from "../oz/security/Pausable.sol";
import {
    AccessControl,
    IAccessControl,
    AccessControlEnumerable
} from "../oz/access/AccessControlEnumerable.sol";

import {ProxyChecker} from "../internal/ProxyChecker.sol";
import {FundForwarder} from "../internal/FundForwarder.sol";
import {IBlacklistable, Blacklistable} from "../internal/Blacklistable.sol";

import {IAuthority} from "./interfaces/IAuthority.sol";

import {Roles} from "../libraries/Roles.sol";

abstract contract Authority is
    Pausable,
    IAuthority,
    ProxyChecker,
    Blacklistable,
    FundForwarder,
    AccessControlEnumerable
{
    /// @dev value is equal to keccak256("Authority_v1")
    bytes32 public constant VERSION =
        0x095dd5e04e0f3f5bce98e4ee904d9f7209827187c4201f036596b2f7fdd602e7;

    constructor(
        address admin_,
        address[] memory operators_,
        bytes32[] memory roles_
    ) payable Pausable() FundForwarder(_deployDefaultTreasury(admin_, "")) {
        _grantRole(Roles.PAUSER_ROLE, admin_);
        _grantRole(Roles.SIGNER_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(Roles.OPERATOR_ROLE, admin_);
        _grantRole(Roles.UPGRADER_ROLE, admin_);
        _grantRole(Roles.PROXY_ROLE, address(this));

        uint256 length = operators_.length;
        if (length != roles_.length) revert Authority__LengthMismatch();

        for (uint256 i; i < length; ) {
            _grantRole(roles_[i], operators_[i]);
            unchecked {
                ++i;
            }
        }
    }

    function changeVault(
        address vault_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _changeVault(vault_);
    }

    /**
     * @dev Grants the specified role to the specified account.
     * Only the admin of the role being granted can call this function.
     * @param role_ bytes32 representing the role being granted
     * @param account_ address of the account receiving the role
     */
    function grantRole(
        bytes32 role_,
        address account_
    )
        public
        override(AccessControl, IAccessControl)
        onlyRole(getRoleAdmin(role_))
    {
        AccessControl.grantRole(role_, account_);
    }

    /// @inheritdoc IBlacklistable
    function setUserStatus(address account_, bool status_) external override {
        _setUserStatus(account_, status_);
    }

    /// @inheritdoc IAuthority
    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) external onlyRole(getRoleAdmin(adminRole)) {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IAuthority
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    /// @inheritdoc IAuthority
    function unpause() external onlyRole(Roles.PAUSER_ROLE) {
        _unpause();
    }

    /// @inheritdoc IAuthority
    function paused()
        public
        view
        override(IAuthority, Pausable)
        returns (bool isPaused)
    {
        return Pausable.paused();
    }

    /// @inheritdoc IAuthority
    function requestAccess(bytes32 role) external whenNotPaused {
        address origin = _txOrigin();
        _checkRole(Roles.OPERATOR_ROLE, origin);

        address sender = _msgSender();
        _onlyProxy(sender, origin);

        _grantRole(Roles.PROXY_ROLE, sender);
        if (role != 0) _grantRole(role, sender);

        emit ProxyAccessGranted(origin, sender);
    }

    function _deployDefaultTreasury(
        address admin_,
        bytes memory data_
    ) internal virtual returns (address);
}
