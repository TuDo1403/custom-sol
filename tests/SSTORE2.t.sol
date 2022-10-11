//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "contracts/libraries/SSTORE2.sol";

contract GasTest {
    using SSTORE2 for bytes;
    using SSTORE2 for bytes32;

    
    string private _tokenURI;
    bytes32 private _tokenURIPtr;

    function setTokenURI(string calldata tokenURI_) external {
        _tokenURI = tokenURI_;
    }

    function setTokenURIv2(string calldata tokenURI_) external {
        _tokenURIPtr = bytes(tokenURI_).write();
    }

    function getTokenURI() external view returns (string memory) {
        return _tokenURI;
    }

    function getTokenURIv2() external view returns (string memory) {
        return string(_tokenURIPtr.read());
    }


}