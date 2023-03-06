// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICommitRevealer} from "./interfaces/ICommitRevealer.sol";

abstract contract CommitRevealer is ICommitRevealer {
    mapping(address => Commitment) public commitments;

    function _commit(
        address account_,
        bytes32 commitment_,
        bytes calldata extraData_
    ) internal virtual {
        commitments[account_] = Commitment(commitment_, block.timestamp);
        emit Commited(account_, commitment_, block.timestamp, extraData_);
    }

    function _checkReveal(
        address account_,
        bytes memory revealBytes_
    ) internal virtual {
        bytes32 commitment;
        assembly {
            mstore(0, account_)
            mstore(32, commitments.slot)
            commitment := sload(keccak256(0, 64))
        }
        if (commitment != keccak256(revealBytes_))
            revert CommitRevealer__InvalidReveal();
    }
}
