// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../internal/Transferable.sol";

import "./interfaces/IWNT.sol";
import "./interfaces/IWNTGate.sol";

/// @dev Upgradable contracts cannot receive ether via `transfer` because of increased SLOAD gas cost.
/// We use this non-upgradeable contract as the recipient and then immediately transfer to an upgradable contract.
/// More details about this issue can be found
/// [here](https://forum.openzeppelin.com/t/openzeppelin-upgradeable-contracts-affected-by-istanbul-hardfork/1616).
contract WNTGate is IWNTGate, Transferable {
    /// @dev Wrapped native token contract
    IWNT public wnt;

    /* ========== CONSTRUCTOR  ========== */

    constructor(IWNT wnt_) payable {
        wnt = wnt_;
    }

    /// @inheritdoc IWNTGate
    function withdraw(address _receiver, uint256 _wad) external override {
        wnt.withdraw(_wad);
        _safeNativeTransfer(_receiver, _wad);
        emit Withdrawal(_receiver, _wad);
    }

    // we need to accept ETH sends to unwrap WETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
