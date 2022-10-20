// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Context.sol";
import "../oz/utils/structs/BitMaps.sol";

import "../libraries/Bytes32Address.sol";

import "./interfaces/IBlacklistable.sol";

abstract contract Blacklistable is IBlacklistable {
    using Bytes32Address for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _blacklisted;

    function setUserStatus(address account_, bool status) external virtual;

    function isBlacklisted(address account_) public view returns (bool) {
        return _blacklisted.get(account_.fillLast96Bits());
    }

    function _setUserStatus(address account_, bool status_) internal {
        _blacklisted.setTo(account_.fillFirst96Bits(), status_);
    }
}
