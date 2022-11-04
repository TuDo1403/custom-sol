// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Context.sol";

import "./Transferable.sol";

error FundForwarder__ForwardFailed();

abstract contract FundForwarder is Context, Transferable {
    address public vault;

    event VaultUpdated(address indexed from, address indexed to);
    event Forwarded(address indexed from, uint256 indexed amount);

    constructor(address vault_) payable {
        _changeVault(vault_);
    }

    receive() external payable virtual {
        (bool ok, ) = vault.call{value: msg.value}("");
        if (!ok) revert FundForwarder__ForwardFailed();
        emit Forwarded(_msgSender(), msg.value);
    }

    function recoverERC20(IERC20 token_, uint256 amount_) external {
        _safeERC20Transfer(token_, vault, amount_);
    }

    function recoverNative() external {
        _safeNativeTransfer(vault, address(this).balance);
    }

    function _changeVault(address vault_) internal {
        emit VaultUpdated(vault, vault_);
        vault = vault_;
    }
}
