// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../libraries/BitMap256.sol";
//import "../oz/utils/structs/BitMaps.sol";

contract BitMap256Test {
    //using BitMaps for BitMaps.BitMap;
    using BitMap256 for BitMap256.BitMap;

    //BitMaps.BitMap private _bitmap;
    BitMap256.BitMap private _bitmap;

    //23981
    function get(address x) external view returns (bool) {
        uint256 uintX;
        assembly {
            uintX := x
        }
        return _bitmap.unsafeGet(uintX);
    }

    //43863
    function set(address x) external {
        uint256 uintX;
        assembly {
            uintX := x
        }
        _bitmap.unsafeSet(uintX);
    }

    // //135170
    // function setBatch(address[] calldata addrs) external {
    //     address[] memory _addrs = addrs;
    //     uint256[] memory uintAddrs;
    //     assembly {
    //         uintAddrs := _addrs
    //     }
    //     _bitmap.setBatch(uintAddrs);
    // }

    function unset(address x) external {
        uint256 uintX;
        assembly {
            uintX := x
        }
        _bitmap.unset(uintX);
    }
}
