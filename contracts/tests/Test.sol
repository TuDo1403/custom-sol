// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
//[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xdD870fA1b7C4700F2BD7f44238821C26f7392148, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2]
//import "../contracts/access/AccessControlEnumerable.sol";
import "../oz/access/AccessControlEnumerable.sol";

contract BitMapTest is AccessControlEnumerable {
    //using EnumerableSet for EnumerableSet.AddressSet;

    //595413 764940
    constructor() payable {}

    //547717 745857
    function grantRoleMulti(bytes32 role_, address[] calldata addrs_) external {
        uint256 length = addrs_.length;
        for (uint256 i; i < length; ) {
            _grantRole(role_, addrs_[i]);
            unchecked {
                ++i;
            }
        }
    }

    // function ozGetAllRoleMemb(bytes32 role_) external view returns (address[] memory) {
    //     return _roleMembers[role_].values();
    // }

    // //137613
    // function litegrantRoleMulti(bytes32 role_, address[] calldata addrs_) external {
    //     bytes32[] memory addrs;
    //     address[] memory _addrs = addrs_;
    //     assembly {
    //         addrs := _addrs
    //     }
    //     uint256 length = addrs.length;
    //     for (uint256 i; i < length; ) {
    //         _grantRole(uint256(role_), addrs[i]);
    //         unchecked {
    //             ++i;
    //         }
    //     }
    // }
}
