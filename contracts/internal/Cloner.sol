// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ICloner.sol";

import "../oz/proxy/Clones.sol";

import "../libraries/Bytes32Address.sol";

abstract contract Cloner is ICloner {
    using Clones for address;
    using Bytes32Address for bytes32;
    using Bytes32Address for address;

    bytes32 private __implement;
    mapping(bytes32 => address[]) private __clones;

    constructor(address implement_) payable {
        _setImplement(implement_);
    }

    function setImplement(address implement_) external virtual;

    function implement() public view returns (address) {
        return __implement.fromFirst20Bytes();
    }

    function _cloneOf(bytes32 salt_)
        internal
        view
        returns (address clone, bool isCloned)
    {
        clone = implement().predictDeterministicAddress(salt_);
        isCloned = clone.code.length != 0;
    }

    function allClonesOf(address implement_)
        external
        view
        returns (address[] memory clones)
    {
        return __clones[implement_.fillLast12Bytes()];
    }

    function _setImplement(address implement_) internal {
        __implement = implement_.fillLast12Bytes();
    }

    function _clone(
        bytes32 salt_,
        bytes4 initSelector_,
        bytes memory initCode_
    ) internal returns (address clone) {
        address _implement = implement();
        clone = _implement.cloneDeterministic(salt_);
        (bool ok, ) = clone.call(abi.encodePacked(initSelector_, initCode_));
        if (!ok) revert Cloner__InitCloneFailed();

        __clones[_implement.fillLast12Bytes()].push(clone);

        emit Cloned(_implement, clone, salt_, clone.codehash);
    }
}