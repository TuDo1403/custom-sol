// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../oz/security/Pausable.sol";
import "../oz/access/AccessControlEnumerable.sol";

import "../internal/ProxyChecker.sol";
import "../internal/Blacklistable.sol";

import "./interfaces/IAuthority.sol";

import "../libraries/Roles.sol";

contract Authority is
    IAuthority,
    Pausable,
    ProxyChecker,
    Blacklistable,
    AccessControlEnumerable
{
    /// @dev value is equal to keccak256("Authority_v1")
    bytes32 public constant VERSION =
        0x095dd5e04e0f3f5bce98e4ee904d9f7209827187c4201f036596b2f7fdd602e7;

    constructor(address admin_) payable {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
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
    function setUserStatus(
        address account_,
        bool status_
    ) external override(Blacklistable, IBlacklistable) {
        _setUserStatus(account_, status_);

        if (status_) emit Blacklisted(account_);
        else emit Whitelisted(account_);
    }

    /// @inheritdoc IAuthority
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external {
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
    function requestAccess(bytes32 role) external {
        address origin = _txOrigin();
        _checkRole(Roles.OPERATOR_ROLE, origin);

        address sender = _msgSender();
        _onlyProxy(sender, origin);

        _grantRole(Roles.PROXY_ROLE, sender);

        if (role != 0) _grantRole(role, sender);

        emit ProxyAccessGranted(sender);
    }
}
