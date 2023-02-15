// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICommitRevealer {
    error CommitRevealer__InvalidReveal();

    struct Commitment {
        bytes32 commitment;
        uint256 blockNumber;
    }

    event Commited(address indexed submitter, bytes32 indexed commiment);

    function commit(bytes32 commitment_) external;
}
