// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "forge-std/Vm.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import "forge-std/console.sol";

import "./TestHelper.t.sol";

import "./utils/MockERC721Rentable.sol";

contract ERC721RentableTest is DSTestPlus {
    address bob;
    address alice;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    MockERC721Rentable token;

    function setUp() public {
        bob = cheats.addr(1);
        alice = cheats.addr(2);

        token = new MockERC721Rentable("Token", "TKN");
    }

    function testUserOwner() public {
        // vm.startPrank(alice);
        // uint256 expires = block.timestamp + 1000;
        // console.logUint(block.timestamp);
        // console.logUint(expires);
        // nft.setUser(1, bob, uint64(expires));
        // vm.stopPrank();
        // assertEq(nft.userOf(1), bob);
        // console.logAddress(nft.userOf(1));
        // assertEq(nft.ownerOf(1), alice);
        token.mint(alice, 1337);

        assertEq(token.balanceOf(alice), 1);
        assertEq(token.ownerOf(1337), alice);
    }

    function testExpires() public {
        // nft.mint(alice, 1);
        // vm.startPrank(alice);
        // uint256 expires = block.timestamp + 1000;
        // console.logUint(block.timestamp);
        // console.logUint(expires);
        // nft.setUser(1, bob, uint64(expires));
        // vm.stopPrank();
        // address paul = cheats.addr(3);
        // vm.prank(alice);
        // nft.transferFrom(alice, paul, 1);
        // vm.warp(block.timestamp + 1001);
        // assertEq(nft.userOf(1), address(0));
        // assertEq(nft.userExpires(1), 0);
    }
}
