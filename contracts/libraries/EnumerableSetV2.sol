// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Array.sol";
import "./SSTORE2.sol";
import "../oz/utils/structs/BitMaps.sol";

library EnumerableSetV2 {
    using Array for uint256[];
    using SSTORE2 for bytes;
    using SSTORE2 for bytes32;
    using BitMaps for BitMaps.BitMap;

    struct Set {
        bytes32 ptr;
        BitMaps.BitMap indexes;
    }

    function _add(Set storage set_, uint256[] memory values_) private {
        set_.ptr = abi.encode(values_).write();
        uint256 length_ = values_.length;
        for (uint256 i; i < length_; ) {
            set_.indexes.set(values_[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _remove(Set storage set_) private {
        delete set_.ptr;
        delete set_.indexes;
    }

    function _contains(Set storage set, uint256 value)
        private
        view
        returns (bool)
    {
        return set.indexes.get(value);
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (uint256)
    {
        return _values(set)[index];
    }

    function _length(Set storage set) private view returns (uint256) {
        return _values(set).length;
    }

    function _values(Set storage set) private view returns (uint256[] memory) {
        return abi.decode(set.ptr.read(), (uint256[]));
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address[] memory value) internal {
        uint256[] memory store;
        assembly {
            store := value
        }
        _add(set._inner, store);
    }

    function remove(AddressSet storage set) internal {
        _remove(set._inner);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _contains(set._inner, store);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address addr)
    {
        uint256 value = _at(set._inner, index);
        assembly {
            addr := value
        }
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
}
