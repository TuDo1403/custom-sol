// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC20Permit
} from "../../oz/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PMT is ERC20Permit {
    constructor(
        string memory name_,
        string memory symbol_
    ) payable ERC20Permit(name_, symbol_) {}

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }
}
