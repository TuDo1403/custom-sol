// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ProxyCheckerUpgradeable.sol";

import "./interfaces/IMultiLevelReferralUpgradeable.sol";

import "../libraries/FixedPointMathLib.sol";

abstract contract MultiLevelReferral is
    ProxyCheckerUpgradeable,
    IMultiLevelReferralUpgradeable
{
    using FixedPointMathLib for uint256;

    uint256 public constant PERCENTAGE_FRACTION = 10_000;

    uint256 public activeTimestampThreshold;

    uint16[] public ratePerTier;

    mapping(address => Referrer) private __referrals;
    mapping(address => uint64) public lastActiveTimestamp;

    function __MultiLevelReferral_init(
        uint64 activeTimestampThreshold_,
        uint16[] memory ratePerTier_
    ) internal onlyInitializing {
        __MultiLevelReferral_init(activeTimestampThreshold_, ratePerTier_);
    }

    function __MultiLevelReferral_init_unchained(
        uint64 activeTimestampThreshold_,
        uint16[] memory ratePerTier_
    ) internal onlyInitializing {
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

        uint256 maxLevel = ratePerTier.length;
        uint256 level;
        for (uint256 i; i < maxLevel; ) {
            if (referrer_ == referree_)
                revert MultiLevelReferral__CircularRefUnallowed();

            unchecked {
                level = ++__referrals[referrer_].level;
                ++i;
            }

            referrer_ = __referrals[referrer_].addr;

            emit LevelUpdated(referrer_, level);
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

    uint256[46] private __gap;
}
