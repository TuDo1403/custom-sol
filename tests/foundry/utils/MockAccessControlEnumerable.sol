// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {AccessControlEnumerable} from "oz/access/AccessControlEnumerable.sol";

contract MockAccessControlEnumerable is AccessControlEnumerable {
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external {
        _setRoleAdmin(role_, adminRole_);
    }

    function setAdmin(address account_) external {
        _grantRole(DEFAULT_ADMIN_ROLE, account_);
    }
}
