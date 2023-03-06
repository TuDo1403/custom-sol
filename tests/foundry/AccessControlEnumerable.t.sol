// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {
    MockAccessControlEnumerable
} from "./utils/MockAccessControlEnumerable.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";
import {console} from "forge-std/console.sol";
import "./TestHelper.t.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

contract AccessControlEnumerableTest is Test {
    MockAccessControlEnumerable public auth;

    address alice;
    address bob;
    address admin;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    constructor() {
        auth = new MockAccessControlEnumerable();
        alice = cheats.addr(1);
        bob = cheats.addr(2);
        admin = cheats.addr(3);
    }

    function setUp() public {
        auth.setAdmin(admin);
    }

    function testGrantRole() public {
        vm.startPrank(admin);

        vm.expectEmit(true, true, true, false);
        bytes32 testerRole = keccak256("TESTER_ROLE");
        emit RoleGranted(testerRole, alice, admin);
        auth.grantRole(testerRole, alice);

        address[] memory roles = auth.getAllRoleMembers(testerRole);
        vm.stopPrank();

        assertEq(roles.length, 1);
        assertEq(roles[0], alice);
        console.logUint(auth.getRoleMemberCount(testerRole));
        assertEq(auth.getRoleMemberCount(testerRole), 1);
    }

    // function testGrantRoleMulti() public {
    //     bytes32 testerRole = keccak256("TESTER_ROLE");
        
    // }
}
