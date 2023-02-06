// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

import "../ERC721.sol";
import "./IERC721Permit.sol";

import "../../../../internal/Signable.sol";

/// @title ERC721 with permit
/// @notice Nonfungible tokens that support an approve via signature, i.e. permit
abstract contract ERC721Permit is ERC721, IERC721Permit, Signable {
    using Bytes32Address for address;

    constructor(
        string memory name_,
        string memory symbol_
    ) payable Signable(name_, "1") ERC721(name_, symbol_) {}

    /// @dev Gets the current nonce for a token ID and then increments it, returning the original value

    /// @inheritdoc IERC721Permit
    function DOMAIN_SEPARATOR() public view override(IERC721Permit, Signable) returns (bytes32) {
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
        if (block.timestamp > deadline_) revert ERC721Permit__Expired();
        address owner = ownerOf(tokenId_);
        if (spender_ == owner) revert ERC721Permit__SelfApproving();

        bytes32 digest;
        assembly {
            let freeMemPtr := mload(0x40)

            mstore(freeMemPtr, __PERMIT_TYPEHASH)
            mstore(add(freeMemPtr, 32), spender_)

            mstore(add(freeMemPtr, 64), tokenId_)

            mstore(add(freeMemPtr, 96), _nonces.slot)

            // increment nonce
            let nonceKey := keccak256(64, 64)
            let nonce := sload(nonceKey)
            sstore(nonceKey, add(1, nonce))

            mstore(add(freeMemPtr, 96), nonce)
            mstore(add(freeMemPtr, 128), deadline_)
            digest := keccak256(freeMemPtr, 160)
        }

        _verify(owner, digest, signature_);

        assembly {
            mstore(0, tokenId_)
            mstore(32, _getApproved.slot)
            sstore(keccak256(0, 64), spender_)
        }
    }

    function nonces(uint256 tokenId_) external view override returns (uint256) {
        return _nonces[bytes32(tokenId_)];
    }
}
