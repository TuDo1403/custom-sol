// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library ErrorHandler {
    function handleRevertIfNotOk(bool ok_, bytes memory revertData_) internal pure {
        if (!ok_)
            assembly {
                revert(
                    // Start of revert data bytes. The 0x20 offset is always the same.
                    add(revertData_, 0x20),
                    // Length of revert data.
                    mload(revertData_)
                )
            }
    }
}
