// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Context.sol";

import "./Transferable.sol";

import "./interfaces/IWithdrawable.sol";

/**
 * @dev Allows tokens and Ether to be withdrawn from the contract
 */
abstract contract Withdrawable is Context, Transferable, IWithdrawable {
    /**
     * @dev Fallback function to receive funds and emit the Received event
     */
    receive() external payable virtual {
        emit Received(_msgSender(), msg.value);
    }

    /// @inheritdoc IWithdrawable
    function withdraw(
        address token_,
        address to_,
        uint256 amount_
    ) external virtual;
}
