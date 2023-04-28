// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "../oz/access/Ownable.sol";
import {Executable} from "../internal/Executable.sol";

import {IERC20} from "../oz/token/ERC20/IERC20.sol";
import {IERC721} from "../oz/token/ERC721/IERC721.sol";
import {IERC1155} from "../oz/token/ERC1155/IERC1155.sol";

contract Wallet is Ownable, Executable {
    constructor() payable Ownable() {}

    receive() external payable {}

    function execute(
        bytes calldata data_,
        CallParams calldata callParams_
    ) external onlyOwner {
        _exec(_msgSender(), data_, callParams_);
    }

    function _beforeExec(
        address sender_,
        bytes calldata data_,
        CallParams calldata callParams_
    ) internal view override {
        // TO-DO
    }
}
