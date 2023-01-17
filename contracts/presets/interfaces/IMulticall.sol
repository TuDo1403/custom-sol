// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMulticall {
    error Multicall__LengthMismatch();
    error Multicall__ExecutionFailed();
    error Multicall__NonDelegateCall();

    event BatchExecuted(
        address indexed operator,
        uint256 indexed value,
        address[] targets,
        uint256[] values,
        bytes[] data,
        bytes[] results
    );

    function multicall(
        address[] calldata targets_,
        uint256[] calldata values_,
        bytes[] calldata data_
    ) external payable returns (bytes[] memory results);
}
