// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz/access/IAccessControlEnumerable.sol";

import "../../internal/interfaces/IBlacklistable.sol";

interface IAuthority is IBlacklistable, IAccessControlEnumerable {
    error Authority__InvalidRole();

    event ProxyAccessGranted(address indexed operator, address indexed proxy);

    /**
     * @dev Sets the admin of the specified role to the specified admin role.
     * @param role bytes32 representing the role to set the admin of
     * @param adminRole bytes32 representing the role to set as the admin of the role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @dev Pauses all functions in the contract. Only callable by accounts with the PAUSER_ROLE.
     */
    function pause() external;

    /**
     * @dev Unpauses all functions in the contract. Only callable by accounts with the PAUSER_ROLE.
     */
    function unpause() external;

    /**
     * @dev Returns true if all functions in the contract are paused, false otherwise.
     * @return isPaused bool isPaused representing the paused state of the contract
     */
    function paused() external view returns (bool isPaused);

    /**
     * @dev Allows a user to request access to the contract as a proxy.
     * Only callable by accounts with the OPERATOR_ROLE and only if the sender is a proxy of the caller.
     * Grants the PROXY_ROLE and the specified role to the sender.
     * @param role bytes32 representing the role to grant to the sender in addition to the PROXY_ROLE
     */
    function requestAccess(bytes32 role) external;
}
