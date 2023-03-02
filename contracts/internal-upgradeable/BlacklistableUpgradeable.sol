// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ContextUpgradeable
} from "../oz-upgradeable/utils/ContextUpgradeable.sol";

import {
    IBlacklistableUpgradeable
} from "./interfaces/IBlacklistableUpgradeable.sol";

import {Bytes32Address} from "../libraries/Bytes32Address.sol";

import {
    BitMapsUpgradeable
} from "../oz-upgradeable/utils/structs/BitMapsUpgradeable.sol";

/**
 * @title BlacklistableUpgradeable
 * @dev Abstract contract that provides blacklist functionality.
 * Users of this contract can add or remove an address from the blacklist.
 * Users can check if an address is blacklisted.
 */
abstract contract BlacklistableUpgradeable is
    ContextUpgradeable,
    IBlacklistableUpgradeable
{
    using Bytes32Address for address;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    BitMapsUpgradeable.BitMap private __blacklisted;

    /// @inheritdoc IBlacklistableUpgradeable
    function isBlacklisted(
        address account_
    ) public view virtual returns (bool) {
        return __blacklisted.get(account_.fillLast96Bits());
    }

    function areBlacklisted(
        address[] calldata accounts_
    ) public view virtual returns (bool) {
        uint256 length = accounts_.length;
        address[] memory memAccounts_ = accounts_;
        uint256[] memory uintAccounts;
        assembly {
            uintAccounts := memAccounts_
        }
        for (uint256 i; i < length; ) {
            if (__blacklisted.get(uintAccounts[i])) return true;
            unchecked {
                ++i;
            }
        }

        return false;
    }

    /**
     * @dev Internal function to set the status of an account.
     * @param account_ The address to change the status of.
     * @param status_ The new status for the address. True for blacklisted, false for not blacklisted.
     */
    function _setUserStatus(address account_, bool status_) internal virtual {
        __blacklisted.setTo(account_.fillLast96Bits(), status_);
        emit UserStatusSet(_msgSender(), account_, status_);
    }

    uint256[49] private __gap;
}
