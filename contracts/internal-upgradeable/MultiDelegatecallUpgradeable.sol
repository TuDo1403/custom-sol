// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/proxy/utils/Initializable.sol";

error MultiDelegatecall__OnlyDelegate();
error MultiDelegatecall__ExecutionFailed();

abstract contract MultiDelegatecallUpgradeable is Initializable {
    address public original;

    function __MultiDelegatecall_init() internal onlyInitializing {
        original = address(this);
    }

    function _multiDelegatecall(bytes[] calldata data_)
        internal
        returns (bytes[] memory results)
    {
        if (address(this) != original) revert MultiDelegatecall__OnlyDelegate();
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
    }
}
