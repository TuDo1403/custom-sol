// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Pausable, IPausable} from "../oz/security/Pausable.sol";
import {
    AccessControl,
    AccessControlEnumerable
} from "../oz/access/AccessControlEnumerable.sol";
import {Multicall} from "./Multicall.sol";

import {ProxyChecker} from "../internal/ProxyChecker.sol";
import {FundForwarder, IFundForwarder} from "../internal/FundForwarder.sol";
import {IBlacklistable, Blacklistable} from "../internal/Blacklistable.sol";

import {ITreasury} from "./interfaces/ITreasury.sol";
import {IAuthority} from "./interfaces/IAuthority.sol";
import {IAccessControl} from "../oz/access/IAccessControl.sol";

import {Roles} from "../libraries/Roles.sol";

abstract contract Authority is
    Pausable,
    Multicall,
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
        bytes32[] memory roles_,
        address[] memory operators_
    ) payable Pausable() {
        _grantRole(Roles.PAUSER_ROLE, admin_);
        _grantRole(Roles.SIGNER_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        bytes32 operatorRole = Roles.OPERATOR_ROLE;
        _grantRole(operatorRole, admin_);
        _grantRole(operatorRole, address(this));

        _grantRole(Roles.UPGRADER_ROLE, admin_);
        _grantRole(Roles.TREASURER_ROLE, admin_);
        _grantRole(Roles.PROXY_ROLE, address(this));
        _grantRole(Roles.TREASURER_ROLE, address(this));

        uint256 length = operators_.length;
        if (length != roles_.length) revert Authority__LengthMismatch();

        for (uint256 i; i < length; ) {
            _grantRole(roles_[i], operators_[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _multicall(
        CallData[] calldata calldata_,
        bytes calldata extraData_
    )
        internal
        override
        onlyRole(Roles.OPERATOR_ROLE)
        nonDelegatecall
        nonReentrant
        returns (bytes[] memory results)
    {
        return super._multicall(calldata_, extraData_);
    }

    function changeVault(
        address vault_
    ) external override onlyRole(Roles.TREASURER_ROLE) {
        _changeVault(vault_);

        bytes32 proxyRole = Roles.PROXY_ROLE;
        uint256 length = getRoleMemberCount(proxyRole);
        bool[] memory success = new bool[](length);
        address proxy;
        for (uint256 i; i < length; ) {
            proxy = getRoleMember(proxyRole, i);

            if (!(proxy == address(this) || proxy.code.length == 0)) {
                (success[i], ) = proxy.call(
                    abi.encodeCall(IFundForwarder.changeVault, (vault_))
                );
            }

            unchecked {
                ++i;
            }
        }

        emit VaultMultiUpdated(_msgSender(), vault_, success);
    }

    /// @inheritdoc IBlacklistable
    function setUserStatus(
        address account_,
        bool status_
    ) external override onlyRole(Roles.PAUSER_ROLE) {
        _setUserStatus(account_, status_);
    }

    /// @inheritdoc IAuthority
    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) external onlyRole(getRoleAdmin(adminRole)) {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IPausable
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    /// @inheritdoc IPausable
    function unpause() external onlyRole(Roles.PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId_
    ) public view override returns (bool) {
        return
            interfaceId_ == type(IAuthority).interfaceId ||
            super.supportsInterface(interfaceId_);
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
}
