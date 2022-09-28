// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../oz-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../oz-upgradeable/utils/ContextUpgradeable.sol";

import "./interfaces/IAccessControlBatchUpgradeable.sol";

import "../libraries/BitMap256.sol";
import "../libraries/Bytes32Address.sol";
import "../libraries/EnumerableSetV2.sol";

abstract contract AccessControlBatchUpgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IAccessControlBatchUpgradeable
{
    using Bytes32Address for address;
    using BitMap256 for BitMap256.BitMap;
    using EnumerableSetV2 for EnumerableSetV2.AddressSet;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // role => adminRole
    mapping(bytes32 => bytes32) internal _adminRoles;
    // user => roles
    mapping(bytes32 => BitMap256.BitMap) internal _roles;
    // role => users
    mapping(bytes32 => EnumerableSetV2.AddressSet) internal _roleMembers;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function grantRoles(bytes32 role, address[] calldata accounts)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRoles(role, accounts);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    function getAllRoleMembers(bytes32 role_)
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        return _roleMembers[role_].values();
    }

    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        return _roleMembers[role].at(index);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roleMembers[role].contains(account);
    }

    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _adminRoles[role];
    }

    function _grantRoles(bytes32 role, address[] calldata accounts) internal {
        _roleMembers[role].add(accounts);
        emit RolesGranted(role, accounts, _msgSender());
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        _roleMembers[role].remove(account);
        emit RoleRevoked(role, account, _msgSender());
    }

    function __AccessControlBatch_init() internal onlyInitializing {}

    function __AccessControlBatch_init_unchained() internal onlyInitializing {}

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account))
            revert AccessControlBatch__RoleMissing(role, account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlBatchUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[48] private __gap;
}
