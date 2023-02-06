// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC20,
    ERC20Permit
} from "../oz/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PMT is ERC20Permit {
    constructor(
        string memory name_,
        string memory symbol_
    ) payable ERC20(name_, symbol_, 18) ERC20Permit(name_) {
        _mint(_msgSender(), 1_000_000_000 * 1 ether);
    }
}
