// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../oz/utils/cryptography/draft-EIP712.sol";

import "./interfaces/ISignable.sol";

import "../libraries/Bytes32Address.sol";

abstract contract Signable is EIP712, ISignable {
    using ECDSA for bytes32;
    using Bytes32Address for address;

    mapping(bytes32 => uint256) internal _nonces;

    function nonces(address sender_)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _nonce(sender_);
    }

    function _verify(
        address sender_,
        address verifier_,
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view virtual {
        _checkVerifier(
            sender_,
            verifier_,
            _hashTypedDataV4(structHash_),
            signature_
        );
    }

    function _verify(
        address sender_,
        address verifier_,
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        _checkVerifier(
            sender_,
            verifier_,
            _hashTypedDataV4(structHash_),
            v,
            r,
            s
        );
    }

    function _checkVerifier(
        address sender_,
        address verifier_,
        bytes32 digest_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        if (digest_.recover(v, r, s) != verifier_)
            revert Signable__InvalidSignature(sender_);
    }

    function _checkVerifier(
        address sender_,
        address verifier_,
        bytes32 digest_,
        bytes calldata signature_
    ) internal view virtual {
        if (digest_.recover(signature_) != verifier_)
            revert Signable__InvalidSignature(sender_);
    }

    function _useNonce(address sender_) internal virtual returns (uint256) {
        unchecked {
            return _nonces[sender_.fillLast12Bytes()]++;
        }
    }

    function _nonce(address sender_) internal view virtual returns (uint256) {
        return _nonces[sender_.fillLast12Bytes()];
    }

    function _splitSignature(bytes calldata signature_)
        internal
        pure
        virtual
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := calldataload(signature_.offset)
            s := calldataload(add(signature_.offset, 0x20))
            v := byte(0, calldataload(add(signature_.offset, 0x40)))
        }
    }

    function DOMAIN_SEPARATOR()
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }
}
