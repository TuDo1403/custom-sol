// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMultiLevelReferral {
    error MultiLevelReferral__ProxyNotAllowed();
    error MultiLevelReferral__ReferralExisted();
    error MultiLevelReferral__InvalidArguments();
    error MultiLevelReferral__CircularRefUnallowed();

    struct Referrer {
        uint8 level;
        uint88 bonus;
        address addr;
    }

    event ReferralAdded(address indexed referrer, address indexed referree);

    event LevelUpdated(address indexed account, uint256 indexed level);
}
