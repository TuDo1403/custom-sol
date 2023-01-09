// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISignableUpgradeable {
    error Signable__InvalidSignature();

    /**
     * @dev Returns the nonce for the given address
     * @param sender_ Address to get the nonce for
     * @return Nonce of the given address
     */
    function nonces(address sender_) external view returns (uint256);

    /**
     * @dev Returns the domain separator for EIP712 v4
     * @return Domain separator for EIP712 v4
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
