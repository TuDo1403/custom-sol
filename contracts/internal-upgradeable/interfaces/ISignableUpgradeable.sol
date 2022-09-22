// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ISignableUpgradeable {
    error Signable__InvalidSignature(address sender);

    function nonces(address sender_) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
