//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    IAuthorityUpgradeable
} from "../../interfaces/IAuthorityUpgradeable.sol";

interface IManagerUpgradeable {
    error Manager__Paused();
    error Manager__NotPaused();
    error Manager__AlreadySet();
    error Manager__Blacklisted();
    error Manager__Unauthorized();
    error Manager__RequestFailed();
    error Manager__InvalidArgument();

    event AuthorityUpdated(
        address indexed operator,
        IAuthorityUpgradeable indexed from,
        IAuthorityUpgradeable indexed to
    );
    event RequestRoleCached(address indexed operator, bytes32 indexed role);

    /**
     * @notice Updates the authority of this contract. This can only be done by an operator.
     * @param authority_ The new authority contract.
     * @dev The authority contract must allow this contract to have the role specified in the constructor.
     * @custom:throws Manager__AlreadySet if the new authority is the same as the current authority.
     * @custom:throws Manager__RequestFailed if the request to the new authority contract fails.
     */
    function updateAuthority(IAuthorityUpgradeable authority_) external;

    /**
     * @notice Returns the authority contract of this contract.
     * @return authority_ is The address of the authority contract.
     */
    function authority()
        external
        view
        returns (IAuthorityUpgradeable authority_);
}
