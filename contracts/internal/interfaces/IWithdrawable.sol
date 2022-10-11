// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz/token/ERC20/IERC20.sol";

interface IWithdrawable {
    event Withdrawn(
        IERC20 indexed token,
        address indexed to,
        uint256 indexed value
    );
    event Received(address indexed sender, uint256 indexed value);

    function withdraw(
        IERC20 from_,
        address to_,
        uint256 amount_
    ) external;
}
