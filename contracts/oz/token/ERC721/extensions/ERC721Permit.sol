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
        string memory symbol_,
        string memory version_
    ) payable Signable(name_, version_) ERC721(name_, symbol_) {}

    /// @dev Gets the current nonce for a token ID and then increments it, returning the original value

    /// @inheritdoc IERC721Permit
    function DOMAIN_SEPARATOR()
        public
        view
        override(IERC721Permit, Signable)
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    /// @dev Value is equal to to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    /// @inheritdoc IERC721Permit
    function permit(
        uint256 tokenId_,
        uint256 deadline_,
        address spender_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (block.timestamp > deadline_) revert ERC721Permit__Expired();
        address owner = ownerOf(tokenId_);
        if (spender_ == owner) revert ERC721Permit__SelfApproving();
        _verify(
            owner,
            keccak256(
                abi.encode(
                    _PERMIT_TYPEHASH,
                    spender_,
                    tokenId_,
                    _useNonce(owner),
                    deadline_
                )
            ),
            v,
            r,
            s
        );
        _getApproved[tokenId_] = spender_.fillLast12Bytes();
    }

    function nonces(uint256 tokenId_) external view override returns (uint256) {
        return _nonces[bytes32(tokenId_)];
    }

    function _useNonce(uint256 tokenId_) internal returns (uint256) {
        unchecked {
            return _nonces[bytes32(tokenId_)]++;
        }
    }
}
