// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../libraries/SSTORE2.sol";

contract SSTORE2Test {
    using SSTORE2 for bytes;
    using SSTORE2 for bytes32;
    struct Test {
        address token;
        uint96 price;
    }

    bytes32 private _dataPtr;

    mapping(address => uint256) public tokenPrices;

    function buildStructArray(
        address[] calldata tokens,
        uint96[] calldata prices
    ) external pure returns (Test[] memory data) {
        uint256 length = tokens.length;
        data = new Test[](tokens.length);
        for (uint256 i; i < length; ) {
            data[i] = Test(tokens[i], prices[i]);
            unchecked {
                ++i;
            }
        }
    }

    function set(Test[] calldata data) external {
        _dataPtr = abi.encode(data).write();
    }

    function set(address[] calldata tokens, uint96[] calldata prices) external {
        uint256 length = tokens.length;
        for (uint256 i; i < length; ) {
            tokenPrices[tokens[i]] = prices[i];
            unchecked {
                ++i;
            }
        }
    }

    function getSingle() external view returns (uint256) {}
}
