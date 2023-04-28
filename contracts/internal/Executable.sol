// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";

import {IExecutable} from "./interfaces/IExecutable.sol";

import {ErrorHandler} from "../libraries/ErrorHandler.sol";

abstract contract Executable is Context, IExecutable {
    using ErrorHandler for bool;

    function _beforeExec(
        address sender_,
        bytes calldata data_,
        CallParams calldata callParams_
    ) internal virtual;

    function _exec(
        address sender_,
        bytes calldata data_,
        CallParams calldata callParams_
    ) internal {
        _beforeExec(sender_, data_, callParams_);

        (bool success, bytes memory returnOrRevertData) = callParams_.to.call{
            value: callParams_.value
        }(abi.encodePacked(callParams_.fnSelector, callParams_.args));

        success.handleRevertIfNotSuccess(returnOrRevertData);

        emit Executed(sender_, returnOrRevertData);
    }
}
