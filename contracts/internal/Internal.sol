// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Context.sol";

abstract contract ModuleIdentity {
    function _checkAccess(bytes4 interfaceId_) internal view virtual;
}

error FACMI__Unauthorized();

abstract contract FunctionalAccessControlForModuleIdentity is
    Context,
    ModuleIdentity
{
    function _checkAccess(bytes4 interfaceId_) internal view override {
        if (!_hasRole(_authorizedRole(interfaceId_), _msgSender()))
            revert FACMI__Unauthorized();
    }

    function _hasRole(
        bytes32 role_,
        address account_
    ) internal view virtual returns (bool);

    function _authorizedRole(
        bytes4 interfaceId_
    ) internal pure virtual returns (bytes32);
}
