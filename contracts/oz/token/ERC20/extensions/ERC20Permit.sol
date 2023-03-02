// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "../ERC20.sol";

import {Signable, Bytes32Address} from "../../../../internal/Signable.sol";

import {IERC20Permit} from "./IERC20Permit.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, Signable {
    using Bytes32Address for address;

    // solhint-disable-next-line var-name-mixedcase
    /// @dev value is equal to keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 private constant __PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) payable Signable(name_, "1") ERC20(name_, symbol_) {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        bytes32 digest;
        bytes32 allowanceKey;
        assembly {
            // if (block.timestamp > deadline) revert ERC20Permit__Expired();
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x614fe41d)
                revert(0x1c, 0x04)
            }

            mstore(0x00, owner)
            mstore(0x20, _nonces.slot)
            let nonceKey := keccak256(0x00, 0x40)
            let nonce := sload(nonceKey)

            let freeMemPtr := mload(0x40)

            mstore(freeMemPtr, __PERMIT_TYPEHASH)
            mstore(add(freeMemPtr, 0x20), owner)
            mstore(add(freeMemPtr, 0x40), spender)
            mstore(add(freeMemPtr, 0x60), value)
            mstore(add(freeMemPtr, 0x80), nonce)
            mstore(add(freeMemPtr, 0xa0), deadline)
            digest := keccak256(freeMemPtr, 0xc0)

            sstore(nonceKey, add(1, nonce))

            mstore(0x20, _allowance.slot)
            allowanceKey := keccak256(0x00, 0x40)
        }

        _verify(owner, digest, v, r, s);

        assembly {
            mstore(0x00, spender)
            mstore(0x20, allowanceKey)
            sstore(keccak256(0x00, 0x40), value)
        }
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     *

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR()
        external
        view
        override(IERC20Permit, Signable)
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    function nonces(address account_) external view returns (uint256 nonce) {
        assembly {
            mstore(0x00, account_)
            mstore(0x20, _nonces.slot)
            nonce := sload(keccak256(0x00, 0x40))
        }
    }
}
