// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "./interfaces/ISignableUpgradeable.sol";

import "../libraries/Bytes32Address.sol";

abstract contract SignableUpgradeable is
    EIP712Upgradeable,
    ISignableUpgradeable
{
    using Bytes32Address for address;
    using ECDSAUpgradeable for bytes32;

    mapping(bytes32 => uint256) internal _nonces;

    function __Signable_init() internal onlyInitializing {}

    function __Signable_init_unchained() internal onlyInitializing {}

    function nonces(address sender_) external view virtual returns (uint256) {
        return _nonce(sender_);
    }

    function _verify(
        address verifier_,
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view virtual {
        _checkVerifier(verifier_, _hashTypedDataV4(structHash_), signature_);
    }

    function _verify(
        address verifier_,
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        _checkVerifier(verifier_, _hashTypedDataV4(structHash_), v, r, s);
    }

    function _checkVerifier(
        address verifier_,
        bytes32 digest_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        if (_recoverSigner(digest_, v, r, s) != verifier_)
            revert Signable__InvalidSignature();
    }

    function _checkVerifier(
        address verifier_,
        bytes32 digest_,
        bytes calldata signature_
    ) internal view virtual {
        if (_recoverSigner(digest_, signature_) != verifier_)
            revert Signable__InvalidSignature();
    }

    function _recoverSigner(bytes32 digest_, bytes calldata signature_)
        internal
        view
        returns (address)
    {
        return digest_.recover(signature_);
    }

    function _recoverSigner(
        bytes32 digest_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        return digest_.recover(v, r, s);
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

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
