// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./oz-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Test is ERC721Upgradeable {

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {}

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {}
}
