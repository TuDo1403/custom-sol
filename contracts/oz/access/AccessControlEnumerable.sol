// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.17;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is
    IAccessControlEnumerable,
    AccessControl
{
    using BitMap256 for BitMap256.BitMap;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getAllRoleMembers(bytes32 role_)
        public
        view
        virtual
        override
        returns (address[] memory membersOfRole)
    {
        bytes32[] memory allMembers = _roleMembers._inner._values;
        assembly {
            membersOfRole := allMembers
        }
        uint256 length = allMembers.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (!_roles[allMembers[i]].get(uint256(role_))) {
                    membersOfRole[i] = membersOfRole[length - 1];
                    ++counter;
                }
                ++i;
            }
        }
        if (counter != 0) {
            assembly {
                mstore(membersOfRole, sub(mload(membersOfRole), counter))
            }
        }
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        return getAllRoleMembers(role)[index];
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return getAllRoleMembers(role).length;
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._grantRole(role, account);
        _roleMembers.add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._revokeRole(role, account);
        _roleMembers.remove(account);
    }
}
