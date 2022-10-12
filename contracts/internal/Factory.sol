// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "../oz/utils/Create2.sol";
import "../oz/utils/structs/BitMaps.sol";

import "./interfaces/IFactory.sol";

import "../libraries/CREATE3.sol";
import "../libraries/Bytes32Address.sol";

abstract contract Factory is IFactory {
    using Clones for address;
    using Bytes32Address for address;
    using Bytes32Address for bytes32;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private __deployed;
    mapping(bytes4 => bytes32) private __implements;

    function implement(bytes4 interfaceId_) public view returns (address) {
        return __implements[interfaceId_].fromFirst20Bytes();
    }

    function deployed(address addr_) public view returns (bool) {
        return __deployed.get(addr_.fillFirst96Bits());
    }

    function cloneOf(bytes4 interfaceId_, bytes32 salt_)
        external
        view
        returns (address clone, bool isCloned)
    {
        clone = implement(interfaceId_).predictDeterministicAddress(
            salt_,
            address(this)
        );
        isCloned = deployed(clone);
    }

    function instanceOf(bytes32 bytecodeHash_, bytes32 salt_)
        external
        view
        returns (address instance, bool isDeployed)
    {
        instance = Create2.computeAddress(salt_, bytecodeHash_);
        isDeployed = deployed(instance);
    }

    function instanceOf(bytes32 salt_)
        external
        view
        returns (address instance, bool isDeployed)
    {
        instance = CREATE3.getDeployed(salt_);
        isDeployed = deployed(instance);
    }

    function _setImplement(bytes4 interfaceId_, address implement_) internal {
        __implements[interfaceId_] = implement_.fillLast12Bytes();
        __deployed.set(implement_.fillLast96Bits());
    }

    function _cheapClone(
        bytes32 salt_,
        bytes4 interfaceId_,
        bytes4 selector_,
        bytes memory args_
    ) internal returns (address clone) {
        address impl = implement(interfaceId_);
        if (impl == address(0)) revert Factory__NonExistImplement();
        clone = impl.cloneDeterministic(salt_);
        (bool ok, ) = clone.call(abi.encodePacked(selector_, args_));
        if (!ok) revert Factory__CloneFailed();

        emit Cloned(impl, salt_, clone);
    }

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes4 interfaceId_,
        bytes memory initCode_,
        bytes memory creationCode_
    ) internal returns (address deployed_) {
        bytes memory bytecode = abi.encodePacked(creationCode_, initCode_);
        deployed_ = Create2.deploy(amount_, salt_, bytecode);

        _setImplement(interfaceId_, deployed_);

        emit Deployed(deployed_, salt_, keccak256(bytecode), 2);
    }

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes4 interfaceId_,
        bytes memory creationCode_
    ) internal returns (address deployed_) {
        deployed_ = CREATE3.deploy(salt_, creationCode_, amount_);

        _setImplement(interfaceId_, deployed_);

        emit Deployed(deployed_, salt_, 0, 3);
    }
}
