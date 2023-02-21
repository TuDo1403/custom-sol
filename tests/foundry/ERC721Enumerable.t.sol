//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Vm.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./TestHelper.t.sol";

import "./utils/MockERC721Enumerable.sol";

contract ERC721EnumerableTest is Test {
    address owner;
    address alice;

    uint256[] ids;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    IMockERC721Enumerable nft;

    constructor() payable {
        owner = cheats.addr(1);
        alice = cheats.addr(2);
        vm.startPrank(owner);

        nft = IMockERC721Enumerable(
            address(
                new MockERC721Enumerable(
                    "Test",
                    "TTK",
                    "https://example-token.com/id"
                )
            )
        );
        vm.stopPrank();
    }

    function setUp() public {
        uint256[] memory idArr = new uint256[](100);

        uint256 id;
        for (uint256 i; i < 100; ) {
            id = uint256(keccak256(abi.encode(i)));
            idArr[i] = id;
            nft.mint(alice, id);
            unchecked {
                ++i;
            }
        }

        ids = idArr;
    }

    function testMintWithCustomId() public {
        nft.mint(alice, 14321995);
    }

    function testMint() public {
        vm.prank(owner);
        nft.mint(alice);
    }

    function testBurn() public {
        nft.burn(ids[0]);
    }
}
