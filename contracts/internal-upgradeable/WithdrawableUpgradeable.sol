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
     * @dev Fallback function to receive funds and emit the Received event
     */
    receive() external payable virtual {
        emit Received(_msgSender(), msg.value);
    }

    function __Withdrawable_init() internal onlyInitializing {}

    function __Withdrawable_init_unchained() internal onlyInitializing {}

    function withdraw(
        address token_,
        address to_,
        uint256 amount_
    ) external virtual;

    uint256[50] private __gap;
}
