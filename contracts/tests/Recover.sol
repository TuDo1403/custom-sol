// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../oz/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../oz/utils/cryptography/ECDSA.sol";

contract SigUtil {
    IERC20Permit public paymentToken;

    mapping(address => uint256) public nonces;

    bytes32 private constant ERC20PERMIT_TYPE_HASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    constructor(IERC20Permit paymentToken_) payable {
        paymentToken = paymentToken_;
    }

    function useNonce(address addr) external returns (uint256) {
        return nonces[addr]++;
    }

    function setPaymentToken(IERC20Permit paymentToken_) external {
        paymentToken = paymentToken_;
    }

    function permitHash(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline
    ) external view returns (bytes32 hash, bytes32 digest, uint256 nonce, bytes32 domainSeparator) {
        hash = keccak256(
            abi.encode(
                ERC20PERMIT_TYPE_HASH,
                owner,
                spender,
                value * 10 ** 18,
                nonce = paymentToken.nonces(owner),
                deadline
            )
        );
        digest = ECDSA.toTypedDataHash(domainSeparator = paymentToken.DOMAIN_SEPARATOR(), hash);
    }

    function splitSignature(
        bytes calldata signature_
    ) external pure returns (uint256 length, uint8 v, bytes32 r, bytes32 s) {
        length = signature_.length;
        if (signature_.length == 65) {
            assembly {
                r := calldataload(signature_.offset)
                s := calldataload(add(signature_.offset, 0x20))
                v := byte(0, calldataload(add(signature_.offset, 0x40)))
            }
        }
    }

    function recover(bytes32 digest, bytes calldata sig) external view returns (address) {
        return ECDSA.recover(digest, sig);
    }

    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (address) {
        return ECDSA.recover(digest, v, r, s);
    }
}
