// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ProxyChecker.sol";

import "./interfaces/IMultiLevelReferral.sol";

import "../libraries/FixedPointMathLib.sol";

abstract contract MultiLevelReferral is ProxyChecker, IMultiLevelReferral {
    using FixedPointMathLib for uint256;

    uint256 public constant PERCENTAGE_FRACTION = 10_000;

    uint256 public immutable activeTimestampThreshold;

    uint16[] public ratePerTier;

    mapping(address => Referrer) private __referrals;
    mapping(address => uint64) public lastActiveTimestamp;

    constructor(uint64 activeTimestampThreshold_, uint16[] memory ratePerTier_)
        payable
    {
        uint256 length = ratePerTier_.length;
        uint256 sum;
        for (uint256 i; i < length; ) {
            unchecked {
                sum += ratePerTier_[i];
                ++i;
            }
        }
        if (sum != PERCENTAGE_FRACTION)
            revert MultiLevelReferral__InvalidArguments();

        ratePerTier = ratePerTier_;
        activeTimestampThreshold = activeTimestampThreshold_;
    }

    function referrerOf(address account_)
        external
        view
        returns (Referrer memory)
    {
        return __referrals[account_];
    }

    function _addReferrer(address referrer_, address referree_) internal {
        if (_isProxy(referree_)) revert MultiLevelReferral__ProxyNotAllowed();
        if (__referrals[referree_].addr != address(0))
            revert MultiLevelReferral__ReferralExisted();

        __referrals[referree_].addr = referrer_;

        uint256 maxLevel = ratePerTier.length;
        uint256 level;
        for (uint256 i; i < maxLevel; ) {
            if (referrer_ == referree_)
                revert MultiLevelReferral__CircularRefUnallowed();

            unchecked {
                level = ++__referrals[referrer_].level;
                ++i;
            }
            emit LevelUpdated(referrer_, level);

            if ((referrer_ = __referrals[referrer_].addr) == address(0)) break;
        }

        emit ReferralAdded(referrer_, referree_);
    }

    function _updateReferrerBonuses(address referree_, uint256 amount_)
        internal
    {
        uint16[] memory rates = ratePerTier;
        uint256 length = rates.length;

        address referrer = referree_;
        uint256 percentageFraction = PERCENTAGE_FRACTION;
        for (uint256 i; i < length; ) {
            referrer = __referrals[referrer].addr;
            unchecked {
                if (_isAccountActiveLately(referrer))
                    __referrals[referrer].bonus += uint16(
                        amount_.mulDivDown(rates[i], percentageFraction)
                    );
                ++i;
            }
        }
    }

    function _isAccountActiveLately(address account_)
        internal
        view
        virtual
        returns (bool)
    {
        return
            block.timestamp - lastActiveTimestamp[account_] <=
            activeTimestampThreshold;
    }

    function _updateLastActiveTimestamp(address account_) internal {
        lastActiveTimestamp[account_] = uint64(block.timestamp);
    }
}
