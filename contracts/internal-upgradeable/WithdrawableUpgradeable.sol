// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/ContextUpgradeable.sol";

import "./TransferableUpgradeable.sol";

import "./interfaces/IWithdrawableUpgradeable.sol";

/**
 * @dev Allows tokens and Ether to be withdrawn from the contract
 */
abstract contract WithdrawableUpgradeable is
    ContextUpgradeable,
    TransferableUpgradeable,
    IWithdrawableUpgradeable
{
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

    function notifyERCTransfer(
        address token_,
        bytes calldata value_,
        bytes calldata data_
    ) external virtual returns (bytes4) {
        emit Received(_msgSender(), address(token_), value_, data_);

        return IWithdrawableUpgradeable.notifyERCTransfer.selector;
    }

    /// @inheritdoc IWithdrawableUpgradeable
    function withdraw(
        address token_,
        address to_,
        uint256 value_,
        bytes calldata data_
    ) external virtual;

    uint256[50] private __gap;
}
