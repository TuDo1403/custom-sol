// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error MultiDelegatecall__OnlyDelegate();
error MultiDelegatecall__ExecutionFailed();

/**
 * @title MultiDelegatecall
 * @dev Abstract contract for performing multiple delegatecalls in a single transaction.
 */
abstract contract MultiDelegatecall {
    /**
     * @dev Address of the original contract
     */
    address private immutable __original;

    event BatchExecuted(
        address indexed operator,
        bytes[] callData,
        bytes[] results
    );

    /**
     * @dev Constructor that saves the address of the original contract
     */
    constructor() payable {
        __original = address(this);
    }

    /**
     * @dev Executes multiple delegatecalls in a single transaction
     * @param data_ Array of calldata for delegatecalls
     * @return results Array of delegatecall results
     */
    function _multiDelegatecall(
        bytes[] calldata data_
    ) internal returns (bytes[] memory results) {
        if (address(this) != __original)
            revert MultiDelegatecall__OnlyDelegate();
        uint256 length = data_.length;
        results = new bytes[](length);
        bool ok;
        for (uint256 i; i < length; ) {
            (ok, results[i]) = address(this).delegatecall(data_[i]);
            if (!ok) revert MultiDelegatecall__ExecutionFailed();
            unchecked {
                ++i;
            }
        }

        emit BatchExecuted(msg.sender, data_, results);
    }
}
