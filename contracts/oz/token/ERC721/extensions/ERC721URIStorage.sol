// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.10;

import {ERC721} from "../ERC721.sol";

import {StringLib} from "../../../../libraries/StringLib.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using StringLib for uint256;

    string internal _baseTokenURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private __tokenURIs;

    constructor(string memory baseURI_) payable {
        _baseTokenURI = baseURI_;
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        ownerOf(tokenId);

        string memory _tokenURI = __tokenURIs[tokenId];

        string memory baseTokenURI_ = _baseTokenURI;
        // If there is no base URI, return the token URI.
        if (bytes(baseTokenURI_).length == 0) return _tokenURI;

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length != 0)
            return
                string(
                    abi.encodePacked(
                        baseTokenURI_,
                        _tokenURI,
                        tokenId.toString()
                    )
                );

        return tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(
        uint256 tokenId,
        string calldata _tokenURI
    ) internal virtual {
        ownerOf(tokenId);
        __tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(__tokenURIs[tokenId]).length != 0)
            delete __tokenURIs[tokenId];
    }
}
