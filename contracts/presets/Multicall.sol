// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";
import {ReentrancyGuard} from "../oz/security/ReentrancyGuard.sol";

import {IMulticall} from "./interfaces/IMulticall.sol";

import {ErrorHandler} from "../libraries/ErrorHandler.sol";

contract Multicall is Context, IMulticall, ReentrancyGuard {
    using ErrorHandler for bool;
    /**
     * @dev Address of the original contract
     */
    address private immutable __original;

    modifier nonDelegatecall() virtual {
        __nonDelegatecall();
        _;
    }

    /**
     * @dev Constructor that saves the address of the original contract
     */
    constructor() payable ReentrancyGuard() {
        __original = address(this);
    }

    function multicall(
        CallData[] calldata calldata_,
        bytes calldata data_
    ) external payable virtual returns (bytes[] memory results) {
        results = _multicall(calldata_, data_);
    }

    function _multicall(
        CallData[] calldata calldata_,
        bytes calldata
    )
        internal
        virtual
        nonDelegatecall
        nonReentrant
        returns (bytes[] memory results)
    {
        uint256 length = calldata_.length;
        results = new bytes[](length);
        bool ok;
        bytes memory result;
        for (uint256 i; i < length; ) {
            (ok, result) = calldata_[i].target.call{value: calldata_[i].value}(
                calldata_[i].data
            );

            ok.handleRevertIfNotSuccess(result);

            results[i] = result;

            unchecked {
                ++i;
            }
        }

        emit BatchExecuted(_msgSender(), msg.value, calldata_, results);
    }

    function __nonDelegatecall() private view {
        if (address(this) == __original)
            revert Multicall__DelegatecallNotAllowed();
    }
}
