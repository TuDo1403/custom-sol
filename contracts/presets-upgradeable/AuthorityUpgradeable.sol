// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITreasury} from "./Treasury.sol";

import {MulticallUpgradeable} from "./MulticallUpgradeable.sol";

import {
    UUPSUpgradeable
} from "../oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    PausableUpgradeable
} from "../oz-upgradeable/security/PausableUpgradeable.sol";
import {
    AccessControlEnumerableUpgradeable
} from "../oz-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import {
    ProxyCheckerUpgradeable
} from "../internal-upgradeable/ProxyCheckerUpgradeable.sol";
import {
    FundForwarderUpgradeable,
    IFundForwarderUpgradeable
} from "../internal-upgradeable/FundForwarderUpgradeable.sol";
import {
    BlacklistableUpgradeable,
    IBlacklistableUpgradeable
} from "../internal-upgradeable/BlacklistableUpgradeable.sol";

import {IAuthority} from "./interfaces/IAuthority.sol";

import {Roles} from "../libraries/Roles.sol";

abstract contract AuthorityUpgradeable is
    IAuthority,
    UUPSUpgradeable,
    PausableUpgradeable,
    MulticallUpgradeable,
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

        address[] memory proxies = getAllRoleMembers(Roles.PROXY_ROLE);

        uint256 length = proxies.length;
        bool[] memory success = new bool[](length);
        for (uint256 i; i < length; ) {
            (success[i], ) = proxies[i].call(
                abi.encodeCall(IFundForwarderUpgradeable.changeVault, (vault_))
            );
            unchecked {
                ++i;
            }
        }

        emit VaultMultiUpdated(_msgSender(), vault_, proxies, success);
    }

    function setRoleAdmin(
        bytes32 role_,
        bytes32 adminRole_
    ) external onlyRole(getRoleAdmin(adminRole_)) {
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

    function supportsInterface(
        bytes4 interfaceId_
    ) public view override returns (bool) {
        return
            interfaceId_ == type(IAuthority).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /// @inheritdoc IBlacklistableUpgradeable
    function setUserStatus(
        address account_,
        bool status_
    ) external override whenPaused onlyRole(Roles.PAUSER_ROLE) {
        _setUserStatus(account_, status_);
    }

    function __Authority_init(
        address admin_,
        bytes calldata,
        bytes32[] calldata roles_,
        address[] calldata operators_
    ) internal virtual onlyInitializing {
        __Multicall_init();
        __Pausable_init_unchained();
        __Authority_init_unchained(admin_, roles_, operators_);
    }

    function __Authority_init_unchained(
        address admin_,
        bytes32[] calldata roles_,
        address[] calldata operators_
    ) internal virtual onlyInitializing {
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
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonDelegatecall
        nonReentrant
        returns (bytes[] memory results)
    {
        return super._multicall(calldata_, extraData_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(Roles.UPGRADER_ROLE) {}

    uint256[50] private __gap;
}
