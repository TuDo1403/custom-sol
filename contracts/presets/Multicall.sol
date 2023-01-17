// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/security/ReentrancyGuard.sol";

import "./interfaces/IMulticall.sol";

contract Multicall is IMulticall, ReentrancyGuard {
    address private immutable __origin;

    constructor() payable ReentrancyGuard() {
        __origin = address(this);
    }

    function multicall(
        address[] calldata targets_,
        uint256[] calldata values_,
        bytes[] calldata data_
    ) external payable nonReentrant returns (bytes[] memory results) {
        if (address(this) == __origin) revert Multicall__NonDelegateCall();

        uint256 length = targets_.length;
        if (length != data_.length || length != values_.length)
            revert Multicall__LengthMismatch();
        results = new bytes[](length);
        bool ok;
        for (uint256 i; i < length; ) {
            (ok, results[i]) = targets_[i].call{value: values_[i]}(data_[i]);
            if (!ok) revert Multicall__ExecutionFailed();
            unchecked {
                ++i;
            }
        }

        emit BatchExecuted(
            msg.sender,
            msg.value,
            targets_,
            values_,
            data_,
            results
        );
    }
}
