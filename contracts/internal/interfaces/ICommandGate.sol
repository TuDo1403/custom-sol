// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICommandGate {
    error CommandGate__UnknownAddress();
    error CommandGate__InvalidArgument();

    struct Asset {
        address token;
        uint256 value;
        address account;
        uint256 deadline;
        bytes signature;
        bytes extraData;
    }

    struct Command {
        bytes4 fnSig;
        address target;
        address vault;
        bytes arguments;
    }

    event Whitelisted(address indexed operator, address indexed addr);

    event VaultsWhitelisted(address indexed operator, address[] vaults);

    event Commanded(
        address indexed operator,
        Asset depositAsset,
        Command command
    );

    function whitelistTarget(address addr_) external;

    function whitelistVaults(address[] calldata vaults_) external;

    function isVaultWhitelisted(address addr_) external view returns (bool);

    function isTargetWhitelisted(address addr_) external view returns (bool);
}
