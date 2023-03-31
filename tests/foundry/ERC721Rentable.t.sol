// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Vm.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./TestHelper.t.sol";

import "./utils/MockERC721Rentable.sol";

import "oz/token/ERC721/IERC721.sol";

contract ERC721RentableTest is Test {
    address bob;
    address alice;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    MockERC721Rentable nft;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Logged when the user of an NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    function setUp() public {
        bob = cheats.addr(1);
        alice = cheats.addr(2);

        nft = new MockERC721Rentable();
        nft.initialize("Token", "TKN");
    }

    function testUserOwner() public {
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(0), alice, 1);
        nft.mint(alice, 1);

        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.ownerOf(1), alice);

        vm.startPrank(alice);

        vm.expectEmit(true, true, true, false);
        emit Approval(alice, bob, 1);

        nft.approve(bob, 1);

        vm.stopPrank();

        vm.startPrank(bob);
        uint256 expires = block.timestamp + 1000;
        console.logUint(block.timestamp);
        console.logUint(expires);

        vm.expectEmit(true, true, false, true);
        emit UpdateUser(1, bob, uint64(expires));

        nft.setUser(1, bob, uint64(expires));
        vm.stopPrank();
        assertEq(nft.userOf(1), bob);
        console.logAddress(nft.userOf(1));

        // token.mint(alice, 1337);

        // assertEq(token.balanceOf(alice), 1);
        // assertEq(token.ownerOf(1337), alice);
    }

    function testExpires() public {
        nft.mint(alice, 1);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.ownerOf(1), alice);

        // nft.mint(alice, 1);
        vm.startPrank(alice);
        uint256 expires = block.timestamp + 1000;
        console.logUint(block.timestamp);
        console.logUint(expires);
        nft.setUser(1, bob, uint64(expires));
        vm.stopPrank();
        address paul = cheats.addr(3);
        vm.prank(alice);
        nft.transferFrom(alice, paul, 1);

        vm.warp(block.timestamp + 1001);
        assertEq(nft.userOf(1), address(0));
        assertEq(nft.userExpires(1), 0);
    }
}
