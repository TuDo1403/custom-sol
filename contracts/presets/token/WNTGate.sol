// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../../oz/utils/Context.sol";

import {Transferable} from "../../internal/Transferable.sol";

import {IWNT} from "./interfaces/IWNT.sol";
import {IWNTGate} from "./interfaces/IWNTGate.sol";

/// @dev Upgradable contracts cannot receive ether via `transfer` because of increased SLOAD gas cost.
/// We use this non-upgradeable contract as the recipient and then immediately transfer to an upgradable contract.
/// More details about this issue can be found
/// [here](https://forum.openzeppelin.com/t/openzeppelin-upgradeable-contracts-affected-by-istanbul-hardfork/1616).
contract WNTGate is IWNTGate, Context, Transferable {
    /// @dev Wrapped native token contract
    bytes32 private __wnt;

    /* ========== CONSTRUCTOR  ========== */

    constructor(IWNT wnt_) payable {
        if (address(wnt_) == address(0) || address(wnt_) == address(this))
            revert WNTGate__InvalidAddress();

        assembly {
            sstore(__wnt.slot, wnt_)
        }
    }

    function wnt() public view returns (IWNT _wnt) {
        assembly {
            _wnt := sload(__wnt.slot)
        }
    }

    /// @inheritdoc IWNTGate
    function withdraw(address _receiver, uint256 _wad) external override {
        wnt().withdraw(_wad);
        _safeNativeTransfer(_receiver, _wad, "");
        emit Withdrawal(_receiver, _wad);
    }

    // we need to accept ETH sends to unwrap WETH
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }
}
