// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ContextUpgradeable
} from "../oz-upgradeable/utils/ContextUpgradeable.sol";

import {DeterministicDeployer} from "../internal/DeterministicDeployer.sol";

import {ProxyCreator} from "../libraries/ProxyCreator.sol";

interface IKillable {
    function kill() external;
}

abstract contract ProxylessUpgrader is
    ContextUpgradeable,
    DeterministicDeployer
{
    IKillable public instance;

    function _destroy() internal {
        instance.kill();
    }

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes memory bytecode_
    ) internal override returns (address _instance) {
        _instance = ProxyCreator.deploy(salt_, bytecode_, amount_);

        instance = IKillable(_instance);

        emit Deployed(
            _msgSender(),
            _instance,
            salt_,
            _instance.codehash,
            type(ProxylessUpgrader).name
        );
    }

    uint256[49] private __gap;
}
