// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "../oz-upgradeable/proxy/utils/Initializable.sol";
import {
    ContextUpgradeable
} from "../oz-upgradeable/utils/ContextUpgradeable.sol";

import {
    IProtocolFeeUpgradeable
} from "./interfaces/IProtocolFeeUpgradeable.sol";

/**
 * @title ProtocolFeeUpgradeable
 * @dev Abstract contract for protocol fees.
 * @dev An implementation of this contract should define the `_percentageFraction` function, which returns the percentage fraction of the fee.
 * @dev The fee amount is calculated as the product of the fee percentage and the fee value.
 */
abstract contract ProtocolFeeUpgradeable is
    Initializable,
    ContextUpgradeable,
    IProtocolFeeUpgradeable
{
    address internal constant _ANY_LABEL = address(1);
    address internal constant _NATIVE_LABEL = address(0);

    FeeInfo public feeInfo;

    function __ProtocolFee_init(
        address token_,
        uint96 feeAmt_
    ) internal virtual onlyInitializing {
        __ProtocolFee_init_unchained(token_, feeAmt_);
    }

    function __ProtocolFee_init_unchained(
        address token_,
        uint96 feeAmt_
    ) internal virtual onlyInitializing {
        _setRoyalty(token_, feeAmt_);
    }

    /**
     * @dev Sets the royalty fee information
     * @param token_ Token address of the fee
     * @param amount_ Fee amount
     */
    function _setRoyalty(address token_, uint96 amount_) internal virtual {
        assembly {
            sstore(feeInfo.slot, or(shl(160, amount_), token_))
        }

        emit ProtocolFeeUpdated(_msgSender(), token_, amount_);
    }

    /**
     * @dev Pure virtual function to return the percentage fraction of the fee
     * @return Percentage fraction of the fee
     */
    function _percentageFraction() internal pure virtual returns (uint256) {
        return 10_000;
    }

    uint256[49] private __gap;
}
