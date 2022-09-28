// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAccessControlBatchUpgradeable {
    error AccessControlBatch__RoleMissing(bytes32 role, address account);

    enum RoleType {
        User2Roles,
        Role2Users
    }

    event RolesGranted(
        bytes32 indexed role,
        address[] indexed accounts,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function grantRoles(bytes32 role, address[] calldata accounts) external;

    function revokeRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getAllRoleMembers(bytes32 role_)
        external
        view
        returns (address[] memory);

    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);
}
