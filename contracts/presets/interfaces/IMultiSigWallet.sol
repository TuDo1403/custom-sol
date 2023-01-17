// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMultiSigWallet {
    error MultiSigWallet__ConfirmedTx();
    error MultiSigWallet__UnexistedTx();
    error MultiSigWallet__Unauthorized();
    error MultiSigWallet__AlreadyExecutedTx();

    struct Transaction {
        address to;
        uint96 value;
        bool executed;
        uint8 numConfirmations;
        bytes data;
    }

    event Deposited(
        address indexed sender,
        uint256 indexed amount,
        uint256 indexed balance
    );

    event TransactionSubmited(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);

    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
}
