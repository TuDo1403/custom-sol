// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

import "../ERC721Upgradeable.sol";
import "./IERC721PermitUpgradeable.sol";

import "../../../../internal-upgradeable/SignableUpgradeable.sol";

/// @title ERC721 with permit
/// @notice Nonfungible tokens that support an approve via signature, i.e. permit
abstract contract ERC721PermitUpgradeable is
    ERC721Upgradeable,
    IERC721PermitUpgradeable,
    SignableUpgradeable
{
    using Bytes32Address for address;

    function __ERC721Permit_init() internal onlyInitializing {}

    function __ERC721Permit_init_unchained() internal onlyInitializing {}

    /// @dev Gets the current nonce for a token ID and then increments it, returning the original value

    /// @inheritdoc IERC721PermitUpgradeable
    function DOMAIN_SEPARATOR()
        public
        view
        override(IERC721PermitUpgradeable, SignableUpgradeable)
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    /// @dev Value is equal to to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPE_HASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    /// @inheritdoc IERC721PermitUpgradeable
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
                    _PERMIT_TYPE_HASH,
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
