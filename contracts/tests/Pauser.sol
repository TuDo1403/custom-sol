// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../oz/security/Pausable.sol";

contract Pauser is Pausable {
    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }
}
