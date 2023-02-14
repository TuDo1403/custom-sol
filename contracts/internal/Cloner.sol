// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";

import {ICloner} from "./interfaces/ICloner.sol";

import {Clones} from "../oz/proxy/Clones.sol";
import {ErrorHandler} from "../libraries/ErrorHandler.sol";
import {Bytes32Address} from "../libraries/Bytes32Address.sol";

abstract contract Cloner is ICloner, Context {
    using Clones for address;
    using Bytes32Address for *;
    using ErrorHandler for bool;

    bytes32 private __implement;
    mapping(bytes32 => bytes32[]) private __clones;

    constructor(address implement_) payable {
        _setImplement(implement_);
    }

    /// @inheritdoc ICloner
    function implement() public view virtual returns (address) {
        return __implement.fromFirst20Bytes();
    }

    /**
     * @notice Returns a cloned contract instance of the given salt
     * @param salt_ The salt used to deterministically generate the clone's address
     * @return clone isCloned The cloned contract instance, and a boolean indicating whether the contract has already been cloned
     */
    function _cloneOf(
        bytes32 salt_
    ) internal view virtual returns (address clone, bool isCloned) {
        clone = implement().predictDeterministicAddress(salt_);
        isCloned = clone.code.length != 0;
    }

    /// @inheritdoc ICloner
    function allClonesOf(
        address implement_
    ) external view virtual returns (address[] memory clones) {
        bytes32[] memory _clones = __clones[implement_.fillLast12Bytes()];
        assembly {
            clones := _clones
        }
    }

    function _setImplement(address implement_) internal virtual {
        address currentImplement;
        assembly {
            currentImplement := sload(__implement.slot)
            sstore(__implement.slot, implement_)
        }

        emit ImplementChanged(currentImplement, implement_);
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
    ) internal virtual returns (address clone) {
        address _implement = implement();
        clone = _implement.cloneDeterministic(salt_);
        if (initSelector_ != 0) {
            (bool ok, bytes memory revertData) = clone.call(
                abi.encodePacked(initSelector_, initCode_)
            );
            ok.handleRevertIfNotSuccess(revertData);
        }

        __clones[_implement.fillLast12Bytes()].push(clone.fillLast12Bytes());

        emit Cloned(_msgSender(), _implement, clone, salt_);
    }
}
