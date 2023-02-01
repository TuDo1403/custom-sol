// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/proxy/Clones.sol";

import "./interfaces/ICloner.sol";

import "../libraries/Bytes32Address.sol";

abstract contract Cloner is ICloner {
    using Clones for address;
    using Bytes32Address for *;

    bytes32 private __implement;
    mapping(bytes32 => address[]) private __clones;

    constructor(address implement_) payable {
        _setImplement(implement_);
        emit ImplementChanged(address(0), implement_);
    }

    /// @inheritdoc ICloner
    function setImplement(address implement_) external virtual;

    /// @inheritdoc ICloner
    function implement() public view returns (address) {
        return __implement.fromFirst20Bytes();
    }

    /**
     * @notice Returns a cloned contract instance of the given salt
     * @param salt_ The salt used to deterministically generate the clone's address
     * @return clone isCloned The cloned contract instance, and a boolean indicating whether the contract has already been cloned
     */
    function _cloneOf(
        bytes32 salt_
    ) internal view returns (address clone, bool isCloned) {
        clone = implement().predictDeterministicAddress(salt_);
        isCloned = clone.code.length != 0;
    }

    /// @inheritdoc ICloner
    function allClonesOf(
        address implement_
    ) external view returns (address[] memory clones) {
        return __clones[implement_.fillLast12Bytes()];
    }

    function _setImplement(address implement_) internal {
        __implement = implement_.fillLast12Bytes();
    }

    /**
     * @notice Creates a cloned contract instance of the given salt
     * @param salt_ The salt used to deterministically generate the clone's address
     * @param initSelector_ The optional selector for the clone's initialization function
     * @param initCode_ The optional data for the clone's initialization function
     * @return clone The cloned contract instance
     */
    function _clone(
        bytes32 salt_,
        bytes4 initSelector_,
        bytes memory initCode_
    ) internal returns (address clone) {
        address _implement = implement();
        clone = _implement.cloneDeterministic(salt_);
        if (initSelector_ != 0) {
            (bool ok, ) = clone.call(
                abi.encodePacked(initSelector_, initCode_)
            );
            if (!ok) revert Cloner__InitCloneFailed();
        }

        __clones[_implement.fillLast12Bytes()].push(clone);

        emit Cloned(_implement, clone, salt_, clone.codehash);
    }
}
