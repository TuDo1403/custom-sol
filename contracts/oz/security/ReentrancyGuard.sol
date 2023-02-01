// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

error ReentrancyGuard__Locked();

abstract contract ReentrancyGuard {
    uint256 private _locked = 1;

    modifier nonReentrant() {
        __nonReentrantBefore();
        _;
        __nonReentrantAfter();
    }

    function __nonReentrantBefore() private {
        if (_locked != 1) revert ReentrancyGuard__Locked();

        _locked = 2;
    }

    function __nonReentrantAfter() private {
        _locked = 1;
    }
}
