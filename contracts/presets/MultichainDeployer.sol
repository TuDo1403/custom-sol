//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Create2, Create2Deployer} from "../internal/DeterministicDeployer.sol";
import {ReentrancyGuard} from "../oz/security/ReentrancyGuard.sol";

import {IMultichainDeployer} from "./interfaces/IMultichainDeployer.sol";

contract MultichainDeployer is
    Create2Deployer,
    ReentrancyGuard,
    IMultichainDeployer
{
    using Create2 for bytes32;

    /// @dev value is equal to keccak256("MultichainDeployer_v1")
    bytes32 public constant VERSION =
        0x9eea8cb98c11fea36be219299200e6b67153ef85e64f26fbca079445a66e02d2;

    constructor() payable ReentrancyGuard() {}

    function deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes calldata bytecode_
    ) external payable nonReentrant returns (address) {
        return _deploy(amount_, salt_, bytecode_);
    }

    function isDeployerOf(
        address instance_,
        bytes32 initCodehash_,
        bytes32 salt_
    ) external view returns (bool) {
        return salt_.computeAddress(initCodehash_) == instance_;
    }
}
