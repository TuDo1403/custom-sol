// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";
import {console} from "forge-std/console.sol";

import {ArrayUtil} from "libraries/ArrayUtil.sol";

contract ArrayUtilTest is DSTestPlus {
    using ArrayUtil for *;
    uint256[] public unTrimmed;

    uint256[] public list;

    uint256[] public set;

    function setUp() public {
        list = [
            10,
            10,
            8,
            10,
            5,
            14,
            8,
            11,
            14,
            12,
            5,
            5,
            12,
            6,
            9,
            9,
            6,
            9,
            13,
            9
        ];

        set = [5, 6, 8, 9, 10, 11, 12, 13, 14];

        unTrimmed = [
            0,
            0,
            5,
            6,
            8,
            0,
            9,
            10,
            0,
            0,
            11,
            12,
            0,
            13,
            14,
            0,
            0,
            0
        ];
    }

    function testTrim() public {
        uint256[] memory _unTrimmed = unTrimmed;
        uint256[] memory _trimmed = set;
        uint256[] memory res = _unTrimmed.trim(0);
        for (uint256 i; i < res.length; ) {
            console.logUint(res[i]);
            unchecked {
                ++i;
            }
        }
        assertUintArrayEq(res, _trimmed);
    }

    function testToSet() public {
        uint256[] memory _testExample = list;
        uint256[] memory _testSet = set;
        uint256[] memory res = _testExample.toSet();
        for (uint256 i; i < res.length; ) {
            console.logUint(res[i]);
            unchecked {
                ++i;
            }
        }
        uint256 length = res.length;
        assertEq(_testSet.length, length);

        bool failFlag;
        for (uint256 i; i < length; ) {
            failFlag = true;

            for (uint256 j; j < length; ) {
                if (_testSet[i] == res[j]) {
                    failFlag = false;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (failFlag) break;

            unchecked {
                ++i;
            }
        }

        assertBoolEq(failFlag, false);
    }
}
