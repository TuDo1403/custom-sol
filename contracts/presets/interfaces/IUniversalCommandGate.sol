// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICommandGate} from "../../internal/interfaces/ICommandGate.sol";

interface IUniversalCommandGate is ICommandGate {
    error UniversalCommandGate__LengthMismatch();
    error UniversalCommandGate__ExecutionFailed();
    error UniversalCommandGate__InsufficientAmount();

    event Refunded(address indexed to, uint256 indexed refundAmt);
}
