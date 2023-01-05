// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/cryptography/draft-EIP712.sol";

import "./interfaces/ISignable.sol";

import "../libraries/Bytes32Address.sol";

/**
 * @title Signable
 * @dev Abstract contract for signing and verifying typed data.
 */
abstract contract Signable is EIP712, ISignable {
    using ECDSA for bytes32;
    using Bytes32Address for address;

    /**
     * @dev Mapping of nonces for each address
     */
    mapping(bytes32 => uint256) internal _nonces;

    /**
     * @dev Constructor that initializes EIP712 with the given name and version
     * @param name_ Name of the typed data
     * @param version_ Version of the typed data
     */
    constructor(
        string memory name_,
        string memory version_
    ) payable EIP712(name_, version_) {}

    /// @inheritdoc ISignable
    function nonces(address sender_) external view virtual returns (uint256) {
        return _nonce(sender_);
    }

    /**
     * @dev Verifies that the signer of the typed data is the given address
     * @param verifier_ Address to verify
     * @param structHash_ Hash of the typed data
     * @param signature_ Signature of the typed data
     */
    function _verify(
        address verifier_,
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view virtual {
        if (_recoverSigner(structHash_, signature_) != verifier_)
            revert Signable__InvalidSignature();
    }

    /**
     * @dev Verifies that the signer of the typed data is the given address
     * @param verifier_ Address to verify
     * @param structHash_ Hash of the typed data
     * @param v ECDSA recovery value
     * @param r ECDSA r value
     * @param s ECDSA s value
     */
    function _verify(
        address verifier_,
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        if (_recoverSigner(structHash_, v, r, s) != verifier_)
            revert Signable__InvalidSignature();
    }

    /**
     * @dev Recovers the signer of the typed data from the signature
     * @param structHash_ Hash of the typed data
     * @param signature_ Signature of the typed data
     * @return Address of the signer
     */
    function _recoverSigner(
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view returns (address) {
        return _hashTypedDataV4(structHash_).recover(signature_);
    }

    /**
     * @dev Recovers the signer of the typed data from the signature
     * @param structHash_ Hash of the typed data
     * @param v ECDSA recovery value
     * @param r ECDSA r value
     * @param s ECDSA s value
     * @return Address of the signer
     */
    function _recoverSigner(
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        return _hashTypedDataV4(structHash_).recover(v, r, s);
    }

    /**
     * @dev Increases the nonce for the given account by 1
     * @param account_ Account to increase the nonce for
     * @return nonce The new nonce for the account
     */
    function _useNonce(
        address account_
    ) internal virtual returns (uint256 nonce) {
        assembly {
            mstore(0x00, account_)
            mstore(0x20, _nonces.slot)
            let key := keccak256(0x00, 0x40)
            nonce := sload(key)
            sstore(key, add(nonce, 1))
        }
    }

    /**
     * @dev Returns the nonce for the given address
     * @param sender_ Address to get the nonce for
     * @return nonce Nonce of the given address
     */
    function _nonce(
        address sender_
    ) internal view virtual returns (uint256 nonce) {
        assembly {
            mstore(0x00, sender_)
            mstore(0x20, _nonces.slot)
            nonce := sload(keccak256(0x00, 0x40))
        }
    }

    /**
     * @dev Merges the ECDSA values into a single signature bytes
     * @param v ECDSA recovery value
     * @param r ECDSA r value
     * @param s ECDSA s value
     * @return signature Combined signature bytes
     */
    function _mergeSignature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory signature) {
        signature = new bytes(65);
        assembly {
            mstore(add(signature, 32), r)
            mstore(add(signature, 64), s)
            mstore(add(signature, 65), v)
        }
        return abi.encodePacked(r, s, v);
    }

    /**
     * @dev Splits the signature bytes into ECDSA values
     * @param signature_ Signature bytes to split
     * @return r s v Tuple of ECDSA values
     */
    function _splitSignature(
        bytes calldata signature_
    ) internal pure virtual returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := calldataload(signature_.offset)
            s := calldataload(add(signature_.offset, 0x20))
            v := byte(0, calldataload(add(signature_.offset, 0x40)))
        }
    }

    /// @inheritdoc ISignable
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}
