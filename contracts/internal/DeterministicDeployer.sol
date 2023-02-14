// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Create2} from "../oz/utils/Create2.sol";

import {Create3} from "../libraries/Create3.sol";

abstract contract DeterministicDeployer {
    event Deployed(
        address indexed deployer,
        address indexed instance,
        bytes32 indexed salt,
        bytes32 bytecodeHash,
        string factory
    );

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes memory bytecode_
    ) internal virtual returns (address instance);
}

abstract contract Create2Deployer is DeterministicDeployer {
    function instanceOf(
        bytes32 salt_,
        bytes32 bytecodeHash_
    ) external view virtual returns (address instance, bool isDeployed) {
        instance = Create2.computeAddress(salt_, bytecodeHash_);
        isDeployed = instance.code.length != 0;
    }

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes memory bytecode_
    ) internal virtual override returns (address instance) {
        instance = Create2.deploy(amount_, salt_, bytecode_);

        emit Deployed(
            msg.sender,
            instance,
            salt_,
            instance.codehash,
            type(Create2Deployer).name
        );
    }
}

abstract contract Create3Deployer is DeterministicDeployer {
    function instanceOf(
        bytes32 salt_
    ) external view virtual returns (address instance, bool isDeployed) {
        instance = Create3.getDeployed(salt_);
        isDeployed = instance.code.length != 0;
    }

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes memory bytecode_
    ) internal virtual override returns (address instance) {
        instance = Create3.deploy(salt_, bytecode_, amount_);

        emit Deployed(
            msg.sender,
            instance,
            salt_,
            instance.codehash,
            type(Create3Deployer).name
        );
    }
}
