// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

import {ERC721Upgradeable} from "../ERC721Upgradeable.sol";
import {
    Bytes32Address,
    SignableUpgradeable
} from "../../../../internal-upgradeable/SignableUpgradeable.sol";

import {IERC721PermitUpgradeable} from "./IERC721PermitUpgradeable.sol";

/// @title ERC721 with permit
/// @notice Nonfungible tokens that support an approve via signature, i.e. permit
abstract contract ERC721PermitUpgradeable is
    ERC721Upgradeable,
    SignableUpgradeable,
    IERC721PermitUpgradeable
{
    using Bytes32Address for address;

    function __ERC721Permit_init(
        string calldata name_,
        string calldata symbol_
    ) internal onlyInitializing {
        __EIP712_init_unchained(name_, "1");
        __ERC721_init_unchained(name_, symbol_);
    }

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
    bytes32 private constant __PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    /// @inheritdoc IERC721PermitUpgradeable
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

    function nonces(
        uint256 tokenId_
    ) external view override returns (uint256) {
        return _nonces[bytes32(tokenId_)];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
