// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/proxy/utils/Initializable.sol";

error MultiDelegatecall__OnlyDelegate();
error MultiDelegatecall__ExecutionFailed();

/**
 * @title MultiDelegatecallUpgradeable
 * @dev Abstract contract for performing multiple delegatecalls in a single transaction.
 */
abstract contract MultiDelegatecallUpgradeable is Initializable {
    /**
     * @dev Address of the original contract
     */
    address private __original;

    event BatchExecuted(
        address indexed operator,
        bytes[] callData,
        bytes[] results
    );

    function __MultiDelegatecall_init() internal onlyInitializing {
        __MultiDelegatecall_init_unchained();
    }

    function __MultiDelegatecall_init_unchained() internal onlyInitializing {
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

    uint256[49] private __gap;
}
