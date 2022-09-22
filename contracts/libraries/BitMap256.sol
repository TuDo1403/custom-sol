// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///@dev can store up to 256 slots
library BitMap256 {
    struct BitMap {
        uint256 data;
    }

    function get(BitMap storage bitmap_, uint256 value_)
        internal
        view
        returns (bool)
    {
        assembly {
            mstore(0x00, value_)
            mstore(0x00, keccak256(0x00, 32))
            mstore(
                0x00,
                and(sload(bitmap_.slot), shl(and(mload(0x00), 0xff), 1))
            )
            return(0x00, 32)
        }
    }

    function setTo(
        BitMap storage bitmap_,
        uint256 value_,
        bool status_
    ) internal {
        if (status_) set(bitmap_, value_);
        else unset(bitmap_, value_);
    }

    function set(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            mstore(0x00, keccak256(0x00, 32))
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(mload(0x00), 0xff), 1))
            )
        }
    }

    function unset(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            mstore(0x00, keccak256(0x00, 32))
            sstore(
                bitmap_.slot,
                and(sload(bitmap_.slot), not(shl(and(mload(0x00), 0xff), 1)))
            )
        }
    }
}
