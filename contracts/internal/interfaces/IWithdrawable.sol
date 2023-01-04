// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz/token/ERC20/IERC20.sol";

interface IWithdrawable {
    event Withdrawn(
        address indexed token,
        address indexed to,
        uint256 indexed value
    );

    /**
     * @dev Event emitted when funds are received by the contract
     */
    event Received(address indexed sender, uint256 indexed value);

    /**
     * @dev Withdraws the given amount of tokens or Ether from the contract
     * @param token_ Address of the token contract to withdraw. If zero address, withdraw Ether.
     * @param to_ Address to send the tokens or Ether to
     * @param amount_ Amount of tokens or Ether to withdraw
     */
    function withdraw(address token_, address to_, uint256 amount_) external;
}
