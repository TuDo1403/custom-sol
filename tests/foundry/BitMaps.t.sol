// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";

import {BitMaps} from "oz/utils/structs/BitMaps.sol";

contract Bitmap256Test is DSTestPlus {
    using BitMaps for *;

    BitMaps.BitMap private bitmap;

    uint256 public constant keyA = 7891;
    uint256 public constant keyB = 451;
    uint256 public constant keyC = 9592328;

    uint256 public hashedKeyA;
    uint256 public hashedKeyB;
    uint256 public hashedKeyC;

    function setUp() public {
        hashedKeyA = uint256(keccak256(abi.encode(keyA)));
        hashedKeyB = uint256(keccak256(abi.encode(keyB)));
        hashedKeyC = uint256(keccak256(abi.encode(keyC)));
    }

    function testStartEmpty() public {
        assertTrue(!bitmap.get(keyA));
        assertTrue(!bitmap.get(keyB));
        assertTrue(!bitmap.get(keyC));

        assertTrue(!bitmap.get(keyA));
        assertTrue(!bitmap.get(keyB));
        assertTrue(!bitmap.get(keyC));
    }

    function testSetToTrue() public {
        bitmap.setTo({index: keyA, shouldSet: true});

        assertTrue(bitmap.get(keyA));
        assertTrue(!bitmap.get(keyB));
        assertTrue(!bitmap.get(keyC));
    }

    function testSetToFalse() public {
        bitmap.setTo({index: keyA, shouldSet: true});
        bitmap.setTo({index: keyA, shouldSet: false});

        assertTrue(!bitmap.get(keyA));
        assertTrue(!bitmap.get(keyB));
        assertTrue(!bitmap.get(keyC));
    }

    function testSetConsecutive() public {
        bitmap.setTo({index: keyA, shouldSet: true});
        bitmap.setTo({index: keyA + 1, shouldSet: true});
        bitmap.setTo({index: keyA + 2, shouldSet: true});
        bitmap.setTo({index: keyA + 3, shouldSet: true});
        bitmap.setTo({index: keyA + 4, shouldSet: true});
        bitmap.setTo({index: keyA + 2, shouldSet: false});
        bitmap.setTo({index: keyA + 4, shouldSet: false});

        assertTrue(bitmap.get(keyA));
        assertTrue(bitmap.get(keyA + 1));
        assertTrue(!bitmap.get(keyA + 2));
        assertTrue(bitmap.get(keyA + 3));
        assertTrue(!bitmap.get(keyA + 4));
    }
}
