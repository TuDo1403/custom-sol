// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
    ERC20Upgradeable
} from "oz-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MockERC20Upgradeable is ERC20Upgradeable {
    function initialize(
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __ERC20_init_unchained(name_, symbol_);
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}
