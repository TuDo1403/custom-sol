// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFactoryUpgradeable {
    error Factory__CloneFailed();
    error Factory__NonExistImplement();

    event Cloned(
        address indexed implement,
        bytes32 indexed salt,
        address indexed clone
    );

    event Deployed(
        address indexed deployed,
        bytes32 indexed salt,
        bytes32 indexed bytecodeHash,
        uint256 version
    );

    function implement(bytes4 interfaceId_) external view returns (address);

    function deployed(address addr_) external view returns (bool);

    function cloneOf(
        bytes4 interfaceId_,
        bytes32 salt_
    ) external view returns (address clone, bool isCloned);

    function instanceOf(
        bytes32 bytecodeHash_,
        bytes32 salt_
    ) external view returns (address instance, bool isDeployed);

    function instanceOf(
        bytes32 salt_
    ) external view returns (address instance, bool isDeployed);
}
