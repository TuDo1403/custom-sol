// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.15;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool isSet)
    {
        assembly {
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            isSet := and(sload(keccak256(0x00, 0x40)), shl(and(index, 0xff), 1))
        }
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) set(bitmap, index);
        else unset(bitmap, index);
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        assembly {
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            let key := keccak256(0x00, 0x40)
            sstore(key, or(sload(key), shl(and(index, 0xff), 1)))
        }
    }

    function setBatch(BitMap storage bitmap_, uint256[] memory values_)
        internal
    {
        assembly {
            let length := mload(values_)
            let i := add(values_, 0x20)
            mstore(0x20, bitmap_.slot)
            for {
                let end := add(i, mul(length, 0x20))
            } lt(i, end) {
                i := add(i, 0x20)
            } {
                mstore(0x00, shr(8, mload(i)))
                let key := keccak256(0x00, 0x40)
                sstore(key, or(sload(key), shl(and(mload(i), 0xff), 1)))
            }
        }
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        unchecked {
            bitmap._data[index >> 8] &= ~(1 << (index & 0xff));
        }

        assembly {
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            let key := keccak256(0x00, 0x40)
            sstore(key, and(sload(key), shl(and(index, 0xff), 1)))
        }
    }
}
