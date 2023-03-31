// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";

import {BitMap256} from "libraries/structs/BitMap256.sol";

contract Bitmap256Test is DSTestPlus {
    using BitMap256 for *;

    BitMap256.BitMap public bitmap;

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
        assertTrue(!bitmap.get({value_: keyA, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyB, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyC, shouldHash_: false}));

        assertTrue(!bitmap.get({value_: keyA, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyB, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyC, shouldHash_: true}));
    }

    function testSetToTrue() public {
        bitmap.setTo({value_: keyA, status_: true, shouldHash_: false});

        assertTrue(bitmap.get({value_: keyA, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyB, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyC, shouldHash_: false}));
    }

    function testHashedSetToTrue() public {
        bitmap.setTo({value_: keyA, status_: true, shouldHash_: true});

        assertTrue(bitmap.get({value_: keyA, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyB, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyC, shouldHash_: true}));
    }

    function testSetToFalse() public {
        bitmap.setTo({value_: keyA, status_: true, shouldHash_: false});
        bitmap.setTo({value_: keyA, status_: false, shouldHash_: false});

        assertTrue(!bitmap.get({value_: keyA, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyB, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyC, shouldHash_: false}));
    }

    function testHashedSetToFalse() public {
        bitmap.setTo({value_: keyA, status_: true, shouldHash_: true});
        bitmap.setTo({value_: keyA, status_: false, shouldHash_: true});

        assertTrue(!bitmap.get({value_: keyA, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyB, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyC, shouldHash_: true}));
    }

    function testSetConsecutive() public {
        bitmap.setTo({value_: keyA, status_: true, shouldHash_: false});
        bitmap.setTo({value_: keyA + 1, status_: true, shouldHash_: false});
        bitmap.setTo({value_: keyA + 2, status_: true, shouldHash_: false});
        bitmap.setTo({value_: keyA + 3, status_: true, shouldHash_: false});
        bitmap.setTo({value_: keyA + 4, status_: true, shouldHash_: false});
        bitmap.setTo({value_: keyA + 2, status_: false, shouldHash_: false});
        bitmap.setTo({value_: keyA + 4, status_: false, shouldHash_: false});

        assertTrue(bitmap.get({value_: keyA, shouldHash_: false}));
        assertTrue(bitmap.get({value_: keyA + 1, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyA + 2, shouldHash_: false}));
        assertTrue(bitmap.get({value_: keyA + 3, shouldHash_: false}));
        assertTrue(!bitmap.get({value_: keyA + 4, shouldHash_: false}));
    }

    function testHashedSetConsecutive() public {
        bitmap.setTo({value_: keyA, status_: true, shouldHash_: true});
        bitmap.setTo({value_: keyA + 1, status_: true, shouldHash_: true});
        bitmap.setTo({value_: keyA + 2, status_: true, shouldHash_: true});
        bitmap.setTo({value_: keyA + 3, status_: true, shouldHash_: true});
        bitmap.setTo({value_: keyA + 4, status_: true, shouldHash_: true});
        bitmap.setTo({value_: keyA + 2, status_: false, shouldHash_: true});
        bitmap.setTo({value_: keyA + 4, status_: false, shouldHash_: true});

        assertTrue(bitmap.get({value_: keyA, shouldHash_: true}));
        assertTrue(bitmap.get({value_: keyA + 1, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyA + 2, shouldHash_: true}));
        assertTrue(bitmap.get({value_: keyA + 3, shouldHash_: true}));
        assertTrue(!bitmap.get({value_: keyA + 4, shouldHash_: true}));
    }
}
