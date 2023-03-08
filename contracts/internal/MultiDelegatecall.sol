// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";
import {ReentrancyGuard} from "../oz/security/ReentrancyGuard.sol";

import {ErrorHandler} from "../libraries/ErrorHandler.sol";

error MultiDelegatecall__OnlyDelegatecall();
error MultiDelegatecall__DelegatecallNotAllowed();

/**
 * @title MultiDelegatecall
 * @dev Abstract contract for performing multiple delegatecalls in a single transaction.
 */
abstract contract MultiDelegatecall is Context, ReentrancyGuard {
    using ErrorHandler for bool;

    /**
     * @dev Address of the original contract
     */
    address private immutable __original;

    modifier onlyDelegatecalll() virtual {
        __onlyDelegateCall();
        _;
    }

    event BatchExecutionDelegated(
        address indexed operator,
        bytes[] callData,
        bytes[] results
    );

    /**
     * @dev Constructor that saves the address of the original contract
     */
    constructor() payable ReentrancyGuard() {
        __original = address(this);
    }

    /**
     * @dev Executes multiple delegatecalls in a single transaction
     * @param data_ Array of calldata for delegatecalls
     * @return results Array of delegatecall results
     */
    function _multiDelegatecall(
        bytes[] calldata data_
    )
        internal
        virtual
        onlyDelegatecalll
        nonReentrant
        returns (bytes[] memory results)
    {
        uint256 length = data_.length;
        results = new bytes[](length);
        bool ok;
        bytes memory result;
        for (uint256 i; i < length; ) {
            (ok, result) = address(this).delegatecall(data_[i]);

            ok.handleRevertIfNotSuccess(result);

            results[i] = result;

            unchecked {
                ++i;
            }
        }

        emit BatchExecutionDelegated(_msgSender(), data_, results);
    }

    function __onlyDelegateCall() private view {
        if (address(this) == __original)
            revert MultiDelegatecall__OnlyDelegatecall();
    }
}
