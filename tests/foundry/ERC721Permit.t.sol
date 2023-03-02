// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Vm.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./TestHelper.t.sol";

import "./utils/SigUtils.t.sol";
import "./utils/MockERC721Permit.sol";

import "libraries/SigUtil.sol";

contract ERC20Test is Test {
    using SigUtil for *;

    MockERC721 internal token;
    SigUtils721 internal sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        token = new MockERC721();
        sigUtils = new SigUtils721(token.DOMAIN_SEPARATOR());

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        token.mint(owner, 1e18);
    }

    function test_Permit() public {
        SigUtils721.Permit memory permit = SigUtils721.Permit({
            spender: spender,
            tokenId: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = SigUtil.merge(v, r, s);
        token.permit(
            permit.spender,
            permit.tokenId,
            permit.deadline,
            signature
        );

        assertEq(token.getApproved(1e18), permit.spender);
        assertEq(token.nonces(1e18), 1);
    }

    function testRevert_ExpiredPermit() public {
        SigUtils721.Permit memory permit = SigUtils721.Permit({
            spender: spender,
            tokenId: 1e18,
            nonce: token.nonces(1e18),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = SigUtil.merge(v, r, s);
        vm.warp(1 days + 1 seconds); // fast forward one second past the deadline

        vm.expectRevert(IERC721Permit.ERC721Permit__Expired.selector);
        token.permit(
            permit.spender,
            permit.tokenId,
            permit.deadline,
            signature
        );
    }

    function testRevert_InvalidSigner() public {
        SigUtils721.Permit memory permit = SigUtils721.Permit({
            spender: spender,
            tokenId: 1e18,
            nonce: token.nonces(1e18),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        bytes memory signature = SigUtil.merge(v, r, s);
        // spender signs owner's approval

        vm.expectRevert(ISignable.Signable__InvalidSignature.selector);
        token.permit(
            permit.spender,
            permit.tokenId,
            permit.deadline,
            signature
        );
    }

    function testRevert_InvalidNonce() public {
        SigUtils721.Permit memory permit = SigUtils721.Permit({
            spender: spender,
            tokenId: 1e18,
            nonce: 1, // owner nonce stored on-chain is 0
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = SigUtil.merge(v, r, s);
        vm.expectRevert(ISignable.Signable__InvalidSignature.selector);
        token.permit(
            permit.spender,
            permit.tokenId,
            permit.deadline,
            signature
        );
    }

    function testRevert_SignatureReplay() public {
        SigUtils721.Permit memory permit = SigUtils721.Permit({
            spender: spender,
            tokenId: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = SigUtil.merge(v, r, s);

        token.permit(
            permit.spender,
            permit.tokenId,
            permit.deadline,
            signature
        );

        vm.expectRevert(ISignable.Signable__InvalidSignature.selector);
        token.permit(
            permit.spender,
            permit.tokenId,
            permit.deadline,
            signature
        );
    }
}
