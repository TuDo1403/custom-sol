// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../libraries/Array.sol";

contract TestDupp {
    using Array for uint256[];

    //47273
    function getSet(
        uint256[] calldata arr
    ) external pure returns (uint256[] memory) {
        return arr.buildSet();
    }
}
