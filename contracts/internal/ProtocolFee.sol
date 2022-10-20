// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/token/ERC20/IERC20.sol";

abstract contract ProtocolFee {
    struct FeeInfo {
        IERC20 token;
        uint96 royalty;
    }

    FeeInfo private __feeInfo;

    function feeInfo() external view returns (IERC20 token, uint256 feeAmt) {
        FeeInfo memory _feeInfo = __feeInfo;
        token = _feeInfo.token;
        feeAmt = _feeInfo.royalty;
    }

    function _setRoyalty(IERC20 token_, uint96 amount_) internal {
        __feeInfo = FeeInfo(token_, amount_);
    }

    function _percentageFraction() internal pure virtual returns (uint256) {
        return 10_000;
    }
}
