// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IProtocolFeeUpgradeable {
    /**
     * @dev Fee information structure
     */
    struct FeeInfo {
        IERC20Upgradeable token;
        uint96 royalty;
    }

    event ProtocolFeeUpdated(
        address indexed operator,
        IERC20Upgradeable indexed payment,
        uint96 indexed royalty
    );

    function setRoyalty(IERC20Upgradeable token_, uint96 feeAmt_) external;

    /**
     * @dev Returns the fee information
     * @return  token feeAmt Token address of the fee and the fee amount
     */
    function feeInfo() external view returns (IERC20Upgradeable token, uint256 feeAmt);
}
