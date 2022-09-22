// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.10;

import "../ERC721.sol";

error ERC721Burnable__OnlyOwnerOrApproved();

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */

abstract contract ERC721Burnable is ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721Burnable__OnlyOwnerOrApproved();
        _burn(tokenId);
    }
}
