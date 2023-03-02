//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC721,
    ERC721Rentable,
    IERC721Rentable
} from "oz/token/ERC721/extensions/ERC721Rentable.sol";

contract MockERC721Rentable is ERC721Rentable {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721Rentable(_name, _symbol) {}

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
