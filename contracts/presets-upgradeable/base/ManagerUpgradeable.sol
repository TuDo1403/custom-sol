//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz-upgradeable/utils/ContextUpgradeable.sol";
import "../../oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IManagerUpgradeable.sol";
import {
    IBlacklistableUpgradeable,
    IAccessControlUpgradeable
} from "../interfaces/IAuthorityUpgradeable.sol";

import "../../libraries/Roles.sol";

abstract contract ManagerUpgradeable is
    UUPSUpgradeable,
    ContextUpgradeable,
    IManagerUpgradeable
{
    bytes32 private __authority;
    bytes32 private __requestedRole;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    modifier onlyWhitelisted() {
        _checkBlacklist(_msgSender());
        _;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function __Manager_init(
        IAuthorityUpgradeable authority_,
        bytes32 role_
    ) internal onlyInitializing {
        __Manager_init_unchained(authority_, role_);
    }

    function __Manager_init_unchained(
        IAuthorityUpgradeable authority_,
        bytes32 role_
    ) internal onlyInitializing {
        assembly {
            sstore(__requestedRole.slot, role_)
        }
        address sender = _msgSender();
        emit RequestRoleCached(sender, role_);

        (bool ok, ) = address(authority_).call(
            abi.encodeCall(IAuthorityUpgradeable.requestAccess, (role_))
        );
        if (!ok) revert Manager__RequestFailed();
        __updateAuthority(authority_);
        emit AuthorityUpdated(
            sender,
            IAuthorityUpgradeable(address(0)),
            authority_
        );
    }

    /// @inheritdoc IManagerUpgradeable
    function updateAuthority(
        IAuthorityUpgradeable authority_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        IAuthorityUpgradeable old = authority();
        if (old == authority_) revert Manager__AlreadySet();
        (bool ok, ) = address(authority_).call(
            abi.encodeCall(
                IAuthorityUpgradeable.requestAccess,
                (__requestedRole)
            )
        );
        if (!ok) revert Manager__RequestFailed();

        __updateAuthority(authority_);

        emit AuthorityUpdated(_msgSender(), old, authority_);
    }

    /// @inheritdoc IManagerUpgradeable
    function authority()
        public
        view
        returns (IAuthorityUpgradeable authority_)
    {
        /// @solidity memory-safe-assembly
        assembly {
            authority_ := sload(__authority.slot)
        }
    }

    /**
     * @notice Returns the address of the authority contract, for internal use.
     * @dev This function is for internal use only and should not be called by external contracts.
     * @return authority_ is the address of the authority contract.
     */
    function _authority() internal view returns (address authority_) {
        /// @solidity memory-safe-assembly
        assembly {
            authority_ := sload(__authority.slot)
        }
    }

    /**
     * @notice Checks if the given account is blacklisted by the authority contract.
     * @param account_ The address to check for blacklisting.
     * @dev This function should be called before allowing the given account to perform certain actions.
     * @custom:throws Manager__Blacklisted if the given account is blacklisted.
     */
    function _checkBlacklist(address account_) internal view {
        (bool ok, ) = _authority().staticcall(
            abi.encodeCall(IBlacklistableUpgradeable.isBlacklisted, (account_))
        );
        if (ok) revert Manager__Blacklisted();
    }

    /**
     * @notice Checks if the given account has the given role.
     * @param role_ The role to check for.
     * @param account_ The address to check for the role.
     * @dev This function should be called before allowing the given account to perform certain actions.
     * @custom:throws Manager__Unauthorized if the given account does not have the given role.
     */
    function _checkRole(bytes32 role_, address account_) internal view {
        if (!_hasRole(role_, account_)) revert Manager__Unauthorized();
    }

    function __updateAuthority(IAuthorityUpgradeable authority_) internal {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(__authority.slot, authority_)
        }
    }

    function _requirePaused() internal view {
        (bool ok, ) = _authority().staticcall(
            abi.encodeCall(IAuthorityUpgradeable.paused, ())
        );
        if (!ok) revert Manager__NotPaused();
    }

    function _requireNotPaused() internal view {
        (bool ok, ) = _authority().staticcall(
            abi.encodeCall(IAuthorityUpgradeable.paused, ())
        );
        if (ok) revert Manager__Paused();
    }

    function _hasRole(
        bytes32 role_,
        address account_
    ) internal view returns (bool ok) {
        (ok, ) = _authority().staticcall(
            abi.encodeCall(IAccessControlUpgradeable.hasRole, (role_, account_))
        );
    }

    function _authorizeUpgrade(
        address implement_
    ) internal override onlyRole(Roles.UPGRADER_ROLE) {}

    uint256[48] private __gap;
}
