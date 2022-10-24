// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz/token/ERC20/IERC20.sol";

interface IProtocolFee {
    struct FeeInfo {
        IERC20 token;
        uint96 royalty;
    }

    function feeInfo() external view returns (IERC20 token, uint256 feeAmt);
}
