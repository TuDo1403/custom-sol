// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/ContextUpgradeable.sol";

import "./TransferableUpgradeable.sol";

error FundForwarder__ForwardFailed();

abstract contract FundForwarderUpgradeable is
    ContextUpgradeable,
    TransferableUpgradeable
{
    address public vault;

    event Forwarded(address indexed from, uint256 indexed amount);

    receive() external payable {
        (bool ok, ) = vault.call{value: msg.value}("");
        if (!ok) revert FundForwarder__ForwardFailed();
        emit Forwarded(_msgSender(), msg.value);
    }

    function __FundForwarder_init(address vault_) internal onlyInitializing {
        vault = vault_;
    }

    function __FundForwarder_init_unchained() internal onlyInitializing {}

    uint256[49] private __gap;
}
