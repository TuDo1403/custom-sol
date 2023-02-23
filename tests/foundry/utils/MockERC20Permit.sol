// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {
    ERC20,
    IERC20Permit,
    ERC20Permit
} from "oz/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ISignable} from "internal/interfaces/ISignable.sol";

contract MockERC20 is ERC20Permit {
    constructor() ERC20Permit("Mock Token", "MTK") {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
