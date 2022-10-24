// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IProtocolFeeUpgradeable {
    struct FeeInfo {
        IERC20Upgradeable token;
        uint96 royalty;
    }

    function feeInfo()
        external
        view
        returns (IERC20Upgradeable token, uint256 feeAmt);
}
