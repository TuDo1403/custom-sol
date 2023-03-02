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
        nft.mint(owner, 14321995);
        nft.mint(owner, 225918748);
    }

    function testSupply() public {
        assertEq(nft.totalSupply(), 2);
    }

    function testIndex() public {
        assertEq(nft.tokenOfOwnerByIndex(owner, 0), 14321995);
    }

    function testIndexOutOfBound() public {
        vm.expectRevert(
            IERC721Enumerable.ERC721Enumerable__OutOfBounds.selector
        );
        nft.tokenOfOwnerByIndex(owner, 2);
    }

    function testInvalidOwner() public {
        vm.expectRevert(
            IERC721Enumerable.ERC721Enumerable__OutOfBounds.selector
        );

        nft.tokenOfOwnerByIndex(alice, 0);
    }

    // function testMintWithCustomId() public {
    //     nft.mint(alice, 14321995);

    //     assertEq(nft.totalSupply(), 101);
    // }

    function beforeEach() internal {
        vm.startPrank(owner);
        nft.approve(alice, 14321995);
        nft.approve(alice, 225918748);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.transferFrom(owner, alice, 14321995);
        nft.transferFrom(owner, alice, 225918748);
        vm.stopPrank();
    }

    function testReturnCorrectTokenIdsForTarget() public {
        beforeEach();

        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.tokenOfOwnerByIndex(alice, 0), 14321995);
        assertEq(nft.tokenOfOwnerByIndex(alice, 1), 225918748);
    }

    function testEmptyCollectionForOriginalOwner() public {
        beforeEach();

        vm.expectRevert(
            IERC721Enumerable.ERC721Enumerable__OutOfBounds.selector
        );

        nft.tokenOfOwnerByIndex(owner, 0);
    }

    function testTokensByIndex() public {
        assertEq(nft.tokenByIndex(0), 14321995);
        assertEq(nft.tokenByIndex(1), 225918748);
    }

    function testRevertIfIndexIsGreaterThanSupply() public {
        vm.expectRevert(
            IERC721Enumerable.ERC721Enumerable__GlobalIndexOutOfBounds.selector
        );

        nft.tokenByIndex(2);
    }

    function testReturnsAllTokensAfterBurningOldAndMintingNew() public {
        uint256 newTokenId = 84931615531;
        uint256 anotherNewTokenId = 84972183064;

        address paul = cheats.addr(3);

        nft.burn(14321995);
        nft.mint(paul, newTokenId);
        nft.mint(paul, anotherNewTokenId);

        assertEq(nft.totalSupply(), 3);

        uint256 id1 = nft.tokenByIndex(0);
        uint256 id2 = nft.tokenByIndex(1);
        uint256 id3 = nft.tokenByIndex(2);

        if (id1 == 14321995 || id2 == 14321995 || id3 == 14321995) revert();

        console.logUint(id1);
        console.logUint(id2);
        console.logUint(id3);
    }

    function testMint() public {
        vm.expectRevert(IERC721.ERC721__InvalidRecipient.selector);
        nft.mint(address(0), 222222);

        assertEq(nft.tokenOfOwnerByIndex(owner, 0), 14321995);
        assertEq(nft.tokenByIndex(0), 14321995);
    }

    function testBurnUnexistedToken() public {
        vm.expectRevert(IERC721.ERC721__NotMinted.selector);
        nft.burn(2423423432423);
    }

    function testRemoveTokenFromTheTokenListOfOwner() public {
        nft.burn(14321995);
        assertEq(nft.tokenOfOwnerByIndex(owner, 0), 225918748);
    }

    function testAdjustAllTokenList() public {
        nft.burn(14321995);
        assertEq(nft.tokenByIndex(0), 225918748);
    }

    function testBurnAllTokens() public {
        nft.burn(14321995);
        nft.burn(225918748);

        assertEq(nft.totalSupply(), 0);

        vm.expectRevert(
            IERC721Enumerable.ERC721Enumerable__GlobalIndexOutOfBounds.selector
        );
        nft.tokenByIndex(0);
    }

    function testStressMint() public {
        // address _owner = owner;
        // IMockERC721Enumerable _nft = nft;
        // for (uint256 i; i < 100; ) {
        //     _nft.mint(_owner, i);
        //     unchecked {
        //         ++i;
        //     }
        // }
        IMockERC721Enumerable _nft = nft;
        address _owner = owner;
        _nft.mint(_owner, 988888);
        _nft.mint(_owner, 534534534);
        _nft.mint(_owner, 534534523);
    }
}
