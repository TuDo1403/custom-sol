// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.10;

import {ERC721, IERC721} from "../ERC721.sol";

interface IERC712Burnable is IERC721 {
    error ERC721Burnable__OnlyOwnerOrApproved();

    function burn(uint256 tokenId) external;
}

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */

abstract contract ERC721Burnable is ERC721, IERC712Burnable {
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
