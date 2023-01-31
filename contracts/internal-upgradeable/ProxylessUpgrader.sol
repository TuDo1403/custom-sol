// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/ContextUpgradeable.sol";

import {DeterministicDeployer} from "../internal/DeterministicDeployer.sol";

import "../libraries/ProxyCreator.sol";

interface IKillable {
    function kill() external;
}

abstract contract ProxylessUpgrader is
    ContextUpgradeable,
    DeterministicDeployer
{
    IKillable public instance;

    function __ProxylessUpgrader_init() internal onlyInitializing {}

    function __ProxylessUpgrader_init_unchained() internal onlyInitializing {}

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
            _instance,
            salt_,
            _instance.codehash,
            type(ProxylessUpgrader).name
        );
    }

    uint256[49] private __gap;
}
