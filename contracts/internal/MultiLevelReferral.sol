// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ProxyChecker.sol";

import "../libraries/FixedPointMathLib.sol";

error MultiLevelReferral__ProxyNotAllowed();
error MultiLevelReferral__ReferralExisted();
error MultiLevelReferral__InvalidArguments();
error MultiLevelReferral__CircularRefUnallowed();

abstract contract MultiLevelReferral is ProxyChecker {
    using FixedPointMathLib for uint256;

    struct Account {
        uint8 level;
        uint16 bonus;
        address addr;
        uint64 lastActiveTimestamp;
    }

    uint256 public constant PERCENTAGE_FRACTION = 10_000;

    uint16[] public ratePerTier;
    mapping(address => Account) private __referrals;

    mapping(address => uint64) private __lastActiveTimestamps;

    event ReferralAdded(address indexed referrer, address indexed referree);

    constructor(uint16[] memory ratePerTier_) payable {
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
    }

    function _addReferrer(address referrer_, address referree_) internal {
        if (_isProxy(referree_)) revert MultiLevelReferral__ProxyNotAllowed();
        if (__referrals[referree_].addr != address(0))
            revert MultiLevelReferral__ReferralExisted();

        uint256 maxLevel = ratePerTier.length;
        for (uint256 i; i < maxLevel; ) {
            if (referrer_ == referree_)
                revert MultiLevelReferral__CircularRefUnallowed();

            unchecked {
                ++__referrals[referrer_].level;
                ++i;
            }

            referrer_ = __referrals[referrer_].addr;
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
                __referrals[referrer].bonus += uint16(
                    amount_.mulDivDown(rates[i], percentageFraction)
                );
                ++i;
            }
        }
    }
}
