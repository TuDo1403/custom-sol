// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWNT {
    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
