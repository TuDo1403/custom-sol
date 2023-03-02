// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

import {ERC721} from "../ERC721.sol";
import {Signable} from "../../../../internal/Signable.sol";

import {IERC721Permit} from "./IERC721Permit.sol";

/// @title ERC721 with permit
/// @notice Nonfungible tokens that support an approve via signature, i.e. permit
abstract contract ERC721Permit is ERC721, IERC721Permit, Signable {
    constructor(
        string memory name_,
        string memory symbol_
    ) payable Signable(name_, "1") ERC721(name_, symbol_) {}

    /// @dev Gets the current nonce for a token ID and then increments it, returning the original value

    /// @inheritdoc IERC721Permit
    function DOMAIN_SEPARATOR()
        public
        view
        override(Signable, IERC721Permit)
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    /// @dev Value is equal to to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant __PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    /// @inheritdoc IERC721Permit
    function permit(
        address spender_,
        uint256 tokenId_,
        uint256 deadline_,
        bytes calldata signature_
    ) external override {
        address owner = ownerOf(tokenId_);

        bytes32 digest;
        assembly {
            // if (block.timestamp > deadline_) revert ERC721Permit__Expired();
            if lt(deadline_, timestamp()) {
                mstore(0x00, 0x7b860b42)
                revert(0x1c, 0x04)
            }
            //  if (spender_ == owner) revert ERC721Permit__SelfApproving();
            if eq(spender_, owner) {
                mstore(0x00, 0x6916b4d5)
                revert(0x1c, 0x04)
            }

            let freeMemPtr := mload(0x40)
            mstore(freeMemPtr, __PERMIT_TYPEHASH)
            mstore(add(freeMemPtr, 0x20), spender_)

            mstore(add(freeMemPtr, 0x40), tokenId_)
            let nonceMemPtr := add(freeMemPtr, 0x60)
            mstore(nonceMemPtr, _nonces.slot)

            // increment nonce
            let nonceKey := keccak256(add(freeMemPtr, 0x40), 0x40)
            let nonce := sload(nonceKey)
            sstore(nonceKey, add(1, nonce))

            mstore(nonceMemPtr, nonce)
            mstore(add(freeMemPtr, 0x80), deadline_)
            digest := keccak256(freeMemPtr, 0xa0)
        }

        _verify(owner, digest, signature_);

        assembly {
            mstore(0x00, tokenId_)
            mstore(0x20, _getApproved.slot)
            sstore(keccak256(0x00, 0x40), spender_)
        }
    }

    function nonces(
        uint256 tokenId_
    ) external view override returns (uint256 nonce) {
        assembly {
            mstore(0x00, tokenId_)
            mstore(0x20, _nonces.slot)
            nonce := sload(keccak256(0x00, 0x40))
        }
    }
}
