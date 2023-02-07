// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";

import {Transferable} from "./Transferable.sol";

import {IWithdrawable} from "./interfaces/IWithdrawable.sol";

/**
 * @dev Allows tokens and Ether to be withdrawn from the contract
 */
abstract contract Withdrawable is Context, Transferable, IWithdrawable {
    /**
     * @dev Fallback function to receive funds when msg.data is empty and emit the Received event
     */
    receive() external payable virtual {
        emit Received(_msgSender(), address(0), abi.encode(msg.value), "");
    }

    /**
     * @dev Fallback function to receive funds when msg.data is not empty and emit the Received event
     */
    fallback() external payable virtual {
        emit Received(
            _msgSender(),
            address(0),
            abi.encode(msg.value),
            msg.data
        );
    }

    function notifyERC20Transfer(
        address token_,
        uint256 value_,
        bytes calldata data_
    ) external virtual returns (bytes4) {
        emit Received(
            _msgSender(),
            address(token_),
            abi.encode(value_),
            data_
        );

        return IWithdrawable.notifyERC20Transfer.selector;
    }

    /// @inheritdoc IWithdrawable
    function withdraw(
        address token_,
        address to_,
        uint256 value_,
        bytes calldata data_
    ) external virtual;
}
