// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
    IERC721Upgradeable,
    ERC721Upgradeable,
    ERC721TokenReceiverUpgradeable
} from "oz-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract MockERC721 is ERC721Upgradeable {
    function initialize(
        string calldata _name,
        string calldata _symbol
    ) external initializer {
        __ERC721_init_unchained(_name, _symbol);
    }

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
