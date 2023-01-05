// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IProtocolFee.sol";

/**
 * @title ProtocolFee
 * @dev Abstract contract for protocol fees.
 * @dev An implementation of this contract should define the `_percentageFraction` function, which returns the percentage fraction of the fee.
 * @dev The fee amount is calculated as the product of the fee percentage and the fee value.
 */
abstract contract ProtocolFee is IProtocolFee {
    FeeInfo private __feeInfo;

    /// @inheritdoc IProtocolFee
    function feeInfo() external view returns (IERC20 token, uint256 feeAmt) {
        assembly {
            let data := sload(__feeInfo.slot)
            token := data
            feeAmt := shr(160, data)
        }
    }

    /**
     * @dev Sets the royalty fee information
     * @param token_ Token address of the fee
     * @param amount_ Fee amount
     */
    function _setRoyalty(IERC20 token_, uint96 amount_) internal {
        assembly {
            sstore(__feeInfo.slot, or(shl(160, amount_), token_))
        }
    }

    /**
     * @dev Pure virtual function to return the percentage fraction of the fee
     * @return Percentage fraction of the fee
     */
    function _percentageFraction() internal pure virtual returns (uint256) {
        return 10_000;
    }
}
