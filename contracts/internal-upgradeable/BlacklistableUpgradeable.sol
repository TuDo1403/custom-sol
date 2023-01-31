// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/ContextUpgradeable.sol";
import "../oz-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import "../libraries/Bytes32Address.sol";

import "./interfaces/IBlacklistableUpgradeable.sol";

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

    function __Blacklistable_init() internal onlyInitializing {}

    function __Blacklistable_init_unchained() internal onlyInitializing {}

    /// @inheritdoc IBlacklistableUpgradeable
    function setUserStatus(address account_, bool status) external virtual;

    /// @inheritdoc IBlacklistableUpgradeable
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
        emit UserStatusSet(_msgSender(), account_, status_);
    }

    uint256[49] private __gap;
}
