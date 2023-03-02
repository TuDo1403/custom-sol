// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {
    ERC721,
    IERC721Permit,
    ERC721Permit
} from "oz/token/ERC721/extensions/ERC721Permit.sol";
import {ISignable} from "internal/interfaces/ISignable.sol";

contract MockERC721 is ERC721Permit {
    constructor() ERC721Permit("Mock Token", "MTK") {}

    function tokenURI(
        uint256
    ) public pure virtual override returns (string memory) {}

    function mint(address to, uint256 tokenId) public virtual {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    function safeMint(address to, uint256 tokenId) public virtual {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        _safeMint(to, tokenId, data);
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {}
}
