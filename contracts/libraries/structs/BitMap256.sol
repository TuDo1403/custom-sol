// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///@dev can store up to 256 slots
library BitMap256 {
    struct BitMap {
        uint256 data;
    }

    function index(
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (uint256 idx) {
        if (shouldHash_) {
            assembly {
                mstore(0x00, value_)
                idx := keccak256(0x00, 32)
            }
        }
        idx = value_ & 0xff;
    }

    function get(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal view returns (bool isSet) {
        if (shouldHash_) {
            assembly {
                mstore(0x00, value_)
                isSet := and(
                    sload(bitmap_.slot),
                    shl(and(keccak256(0x00, 32), 0xff), 1)
                )
            }
        }
        assembly {
            isSet := and(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
        }
    }

    function get(
        uint256 bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (bool isSet) {
        if (shouldHash_) {
            assembly {
                mstore(0x00, value_)
                isSet := and(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
            }
        }
        assembly {
            isSet := and(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function setData(BitMap storage bitmap_, uint256 value) internal {
        assembly {
            sstore(bitmap_.slot, value)
        }
    }

    function setTo(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_,
        bool status_
    ) internal {
        if (status_) set(bitmap_, value_, shouldHash_);
        else unset(bitmap_, value_, shouldHash_);
    }

    function set(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal {
        if (shouldHash_) {
            assembly {
                mstore(0x00, value_)
                sstore(
                    bitmap_.slot,
                    or(
                        sload(bitmap_.slot),
                        shl(and(keccak256(0x00, 32), 0xff), 1)
                    )
                )
            }
        }

        assembly {
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
            )
        }
    }

    function set(
        uint256 bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (uint256 bitmap) {
        if (shouldHash_) {
            assembly {
                mstore(0x00, value_)
                bitmap := or(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
            }
        }
        assembly {
            bitmap := or(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function unset(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal {
        if (shouldHash_) {
            assembly {
                mstore(0x00, value_)
                sstore(
                    bitmap_.slot,
                    and(
                        sload(bitmap_.slot),
                        not(shl(and(keccak256(0x00, 32), 0xff), 1))
                    )
                )
            }
        }
        assembly {
            sstore(
                bitmap_.slot,
                and(sload(bitmap_.slot), not(shl(and(value_, 0xff), 1)))
            )
        }
    }

    function unset(
        uint256 bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (uint256 bitmap) {
        if (shouldHash_) {
            assembly {
                mstore(0x00, value_)
                bitmap := and(
                    bitmap_,
                    not(shl(and(keccak256(0x00, 32), 0xff), 1))
                )
            }
        }
        assembly {
            bitmap := and(bitmap_, not(shl(and(value_, 0xff), 1)))
        }
    }
}
