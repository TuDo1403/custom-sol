// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITreasury, Treasury} from "./Treasury.sol";

import "../oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../oz-upgradeable/security/PausableUpgradeable.sol";
import "../oz-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "../internal-upgradeable/ProxyCheckerUpgradeable.sol";
import "../internal-upgradeable/FundForwarderUpgradeable.sol";
import "../internal-upgradeable/BlacklistableUpgradeable.sol";

import "./interfaces/IAuthority.sol";

import "../libraries/Roles.sol";

abstract contract AuthorityUpgradeable is
    IAuthority,
    UUPSUpgradeable,
    PausableUpgradeable,
    ProxyCheckerUpgradeable,
    FundForwarderUpgradeable,
    BlacklistableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    /// @dev value is equal to keccak256("Authority_v1")
    bytes32 public constant VERSION =
        0x095dd5e04e0f3f5bce98e4ee904d9f7209827187c4201f036596b2f7fdd602e7;

    function changeVault(
        address vault_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _changeVault(vault_);
    }

    function setRoleAdmin(
        bytes32 role_,
        bytes32 adminRole_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role_, adminRole_);
    }

    function requestAccess(bytes32 role) external whenNotPaused {
        address origin = _txOrigin();
        _checkRole(Roles.OPERATOR_ROLE, origin);

        address sender = _msgSender();
        _onlyProxy(sender, origin);

        _grantRole(Roles.PROXY_ROLE, sender);
        if (role != 0) _grantRole(role, sender);

        emit ProxyAccessGranted(origin, sender);
    }

    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(Roles.PAUSER_ROLE) {
        _unpause();
    }

    function paused()
        public
        view
        override(IAuthority, PausableUpgradeable)
        returns (bool)
    {
        return PausableUpgradeable.paused();
    }

    function setUserStatus(
        address account_,
        bool status_
    ) external override whenPaused onlyRole(Roles.PAUSER_ROLE) {
        _setUserStatus(account_, status_);
    }

    function __Authority__init(
        address admin_,
        bytes calldata data_,
        address[] calldata operators_,
        bytes32[] calldata roles_
    ) internal virtual onlyInitializing {
        __Pausable_init_unchained();
        __Authority_init_unchained(admin_, operators_, roles_);
        __FundForwarder_init_unchained(_deployDefaultTreasury(admin_, data_));
    }

    function __Authority_init_unchained(
        address admin_,
        address[] calldata operators_,
        bytes32[] calldata roles_
    ) internal virtual onlyInitializing {
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

    function _deployDefaultTreasury(
        address admin_,
        bytes memory data_
    ) internal virtual returns (address);

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(Roles.UPGRADER_ROLE) {}

    uint256[50] private __gap;
}
