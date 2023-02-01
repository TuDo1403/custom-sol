// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz/token/ERC20/IERC20.sol";

interface IProtocolFee {
    /**
     * @dev Fee information structure
     */
    struct FeeInfo {
        IERC20 token;
        uint96 royalty;
    }

    event ProtocolFeeUpdated(
        address indexed operator,
        IERC20 indexed token,
        uint96 indexed royalty
    );

    /**
     * @dev Returns the fee information
     * @return  token feeAmt Token address of the fee and the fee amount
     */
    function feeInfo() external view returns (IERC20 token, uint256 feeAmt);

    function setRoyalty(IERC20 token_, uint96 amount_) external;
}
