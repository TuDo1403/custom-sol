// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMulticall {
    error Multicall__DelegatecallNotAllowed();

    struct CallData {
        address target;
        uint256 value;
        bytes data;
    }

    event BatchExecuted(
        address indexed account,
        uint256 indexed value,
        CallData[] callData,
        bytes[] results
    );

    function multicall(
        CallData[] calldata calldata_,
        bytes calldata data_
    ) external payable returns (bytes[] memory results);
}
