// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Context.sol";
import "../oz/utils/structs/BitMaps.sol";

import "../libraries/Bytes32Address.sol";

import "./interfaces/IBlacklistable.sol";

/**
 * @title Blacklistable
 * @dev Abstract contract that provides blacklist functionality.
 * Users of this contract can add or remove an address from the blacklist.
 * Users can check if an address is blacklisted.
 */
abstract contract Blacklistable is IBlacklistable {
    using Bytes32Address for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private __blacklisted;

    /// @inheritdoc IBlacklistable
    function setUserStatus(address account_, bool status) external virtual;

    /// @inheritdoc IBlacklistable
    function isBlacklisted(address account_) public view returns (bool) {
        return __blacklisted.get(account_.fillLast96Bits());
    }

    /**
     * @dev Internal function to set the status of an account.
     * @param account_ The address to change the status of.
     * @param status_ The new status for the address. True for blacklisted, false for not blacklisted.
     */
    function _setUserStatus(address account_, bool status_) internal {
        __blacklisted.setTo(account_.fillLast96Bits(), status_);
    }
}
