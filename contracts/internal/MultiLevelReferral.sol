// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ProxyChecker} from "./ProxyChecker.sol";

import {IMultiLevelReferral} from "./interfaces/IMultiLevelReferral.sol";

import {FixedPointMathLib} from "../libraries/FixedPointMathLib.sol";

/**
 * @title MultiLevelReferral
 * @author Tu Do
 * @dev Abstract contract for a multi-level referral system
 * @dev When a user is referred, their referrer is set and their level is updated
 * @dev Referrers are rewarded a percentage of the amount spent by their referree
 * @dev Referral bonuses are only rewarded to active referrers
 */
abstract contract MultiLevelReferral is ProxyChecker, IMultiLevelReferral {
    using FixedPointMathLib for uint256;

    uint256 public constant PERCENTAGE_FRACTION = 10_000;

    /**
     * @dev Timestamp threshold for an account to be considered active
     */
    uint256 public immutable activeTimestampThreshold;

    /**
     * @dev Percentage of amount spent by referree that is rewarded to referrer
     * @dev Each element in the array corresponds to the referral rate per level
     */
    uint16[] public ratePerTier;

    /**
     * @dev Map of referree addresses to their referral information
     */
    mapping(address => Referrer) private __referrals;

    /**
     * @dev Map of account addresses to their last active timestamp
     */
    mapping(address => uint64) public lastActiveTimestamp;

    /**
     * @dev Constructor that initializes the activeTimestampThreshold and ratePerTier values
     * @param activeTimestampThreshold_ Timestamp threshold for an account to be considered active
     * @param ratePerTier_ Percentage of amount spent by referree that is rewarded to referrer for each level
     * @dev The sum of the ratePerTier values must equal to 10,000
     */
    constructor(
        uint64 activeTimestampThreshold_,
        uint16[] memory ratePerTier_
    ) payable {
        // Check that the sum of the ratePerTier values is equal to 10,000
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

    /// @inheritdoc IMultiLevelReferral
    function referrerOf(
        address account_
    ) external view returns (Referrer memory) {
        return __referrals[account_];
    }

    /**
     * @dev Sets the referrer of an account and updates their referral level
     * @param referrer_ Referrer address
     * @param referree_ Referree address
     * @dev Referree must not be a proxy contract
     * @dev Referree must not already have a referrer
     * @dev Referrer must not be the same as the referree to prevent circular referrals
     * @dev If the referrer of the referrer is the same as the referree, the transaction reverts
     */
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

    /**
     * @dev Updates the bonuses of all referrers for the given referree
     * @param referree_ Address of the referree
     * @param amount_ Amount of reward that the referree received
     */
    function _updateReferrerBonuses(
        address referree_,
        uint256 amount_
    ) internal {
        uint16[] memory rates = ratePerTier;
        uint256 length = rates.length;

        address referrer = referree_;
        uint256 percentageFraction = PERCENTAGE_FRACTION;
        for (uint256 i; i < length; ) {
            referrer = __referrals[referrer].addr;
            unchecked {
                if (_isAccountActiveLately(referrer))
                    __referrals[referrer].bonus += uint88(
                        amount_.mulDivDown(rates[i], percentageFraction)
                    );
                ++i;
            }
        }
    }

    /**
     * @dev Returns whether the given account has been active recently
     * @param account_ Account to check for recent activity
     * @return True if the given account has been active recently, false otherwise
     */
    function _isAccountActiveLately(
        address account_
    ) internal view virtual returns (bool) {
        return
            block.timestamp - lastActiveTimestamp[account_] <=
            activeTimestampThreshold;
    }

    /**
     * @dev Updates the last active timestamp for the given account
     * @param account_ Account to update the last active timestamp for
     */
    function _updateLastActiveTimestamp(address account_) internal {
        lastActiveTimestamp[account_] = uint64(block.timestamp);
    }
}
