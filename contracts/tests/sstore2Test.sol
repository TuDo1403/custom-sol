// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../libraries/SSTORE2.sol";

contract SSTORE2Test {
    bytes32 private _dataPtr;
    address private _dataPtr1;

    uint256 private _num;
    string private _str;

    // function setNum(uint256 n) external {
    //     _dataPtr = SSTORE2.write(n);
    // }

    function setNum1(uint256 n) external {
        //_dataPtr = SSTORE2.write(n);
        _num = n;
    }

    //209249
    function setText(string calldata _text) external {
        _dataPtr = SSTORE2.write(bytes(_text));
    }

    //28564
    function getText() external view returns (string memory) {
        //return string(SSTORE2.read(_dataPtr1));

        return string(SSTORE2.read(_dataPtr));
    }

    //498370
    function setText1(string calldata _text) external {
        _str = _text;
    }

    function getText1() external view returns (string memory) {
        return _str;
    }
}
