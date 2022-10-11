//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
}
