// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import {Context} from "../utils/Context.sol";
import {Bytes32Address} from "../../libraries/Bytes32Address.sol";

interface IOwnable {
    error Ownable__Unauthorized();
    error Ownable__NonZeroAddress();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address _owner);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context, IOwnable {
    using Bytes32Address for *;

    bytes32 private __owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() payable {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address _owner) {
        assembly {
            _owner := sload(__owner.slot)
        }
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner(address sender_) internal view virtual {
        if (__owner != sender_.fillLast12Bytes())
            revert Ownable__Unauthorized();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable__Unauthorized();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        assembly {
            log3(
                0x00,
                0x00,
                /// @dev value is equal to kecak256("OwnershipTransferred(address,address)");
                0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0,
                sload(__owner.slot),
                newOwner
            )
            sstore(__owner.slot, newOwner)
        }
    }
}
