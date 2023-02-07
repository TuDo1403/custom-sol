// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BitMap256} from "./BitMap256.sol";

library Array {
    using BitMap256 for uint256;

    // 100 record ~= 60k gas
    function buildSet(
        uint256[] memory arr_
    ) internal pure returns (uint256[] memory) {
        uint256 length = arr_.length;
        {
            uint256 val;
            uint256 bitmap;
            for (uint256 i; i < length; ) {
                unchecked {
                    val = arr_[i];
                    while (
                        length > i &&
                        bitmap.get({value_: val, shouldHash_: true})
                    ) val = arr_[--length];
                    bitmap = bitmap.set({
                        value_: arr_[i] = val,
                        shouldHash_: true
                    });
                    ++i;
                }
            }
        }
        assembly {
            mstore(arr_, length)
        }
        return arr_;
    }

    function trimZero(
        uint256[] memory arr_
    ) internal pure returns (uint256[] memory res) {
        res = arr_;
        uint256 length = res.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
        assembly {
            mstore(res, counter)
        }
    }

    function trimZero(
        uint256[256] memory arr_,
        uint256 size_
    ) internal pure returns (uint256[] memory res) {
        res = new uint256[](size_);
        uint256 length = arr_.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
    }
}
