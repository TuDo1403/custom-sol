// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/token/ERC20/ERC20.sol";

contract PMT is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    ) payable ERC20(name_, symbol_, 18) {
        _mint(_msgSender(), 1_000_000_000 * 1e18);
    }
}
