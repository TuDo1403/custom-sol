//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC721Burnable,
    ERC721PresetMinterPauserAutoId
} from "oz/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

import {
    IERC721,
    IERC721Enumerable
} from "oz/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMockERC721Enumerable is IERC721Enumerable {
    function burn(uint256 tokenId) external;

    function mint(address to) external;

    function mint(address to, uint256 tokenId) external;
}

contract MockERC721Enumerable is
    IMockERC721Enumerable,
    ERC721PresetMinterPauserAutoId
{
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) {}

    function burn(
        uint256 tokenId
    ) public override(ERC721Burnable, IMockERC721Enumerable) {
        _burn(tokenId);
    }

    function mint(
        address to
    ) public override(ERC721PresetMinterPauserAutoId, IMockERC721Enumerable) {
        ERC721PresetMinterPauserAutoId.mint(to);
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {}
}