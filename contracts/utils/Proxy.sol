// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error Proxy__NonProxy();
error Proxy__OnlyProxy();

abstract contract Proxy {
    function _isProxy(address sender_) internal view returns (bool) {
        return sender_ != tx.origin && sender_.code.length != 0;
    }

    function _onlyProxy(address sender_) internal view {
        if (!_isProxy(sender_)) revert Proxy__OnlyProxy();
    }

    function _nonProxy(address sender_) internal view {
        if (_isProxy(sender_)) revert Proxy__NonProxy();
    }
}
