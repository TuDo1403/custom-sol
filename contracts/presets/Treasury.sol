//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAuthority, Manager} from "./base/Manager.sol";

import "../internal/Signable.sol";
import "../internal/ProxyChecker.sol";
import "../internal/Withdrawable.sol";

import "./interfaces/ITreasury.sol";
import "../oz/token/ERC20/IERC20.sol";
import {IERC721, ERC721TokenReceiver} from "../oz/token/ERC721/ERC721.sol";
import {
    IERC1155,
    IERC1155Receiver
} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // TODO: update oz-custom

import "../libraries/Roles.sol";
import "../libraries/Bytes32Address.sol";

import "../oz/utils/structs/BitMaps.sol";
import "../oz/utils/introspection/ERC165Checker.sol";

contract Treasury is
    Manager,
    Signable,
    ITreasury,
    ProxyChecker,
    Withdrawable,
    IERC1155Receiver,
    ERC721TokenReceiver
{
    using ERC165Checker for address;
    using BitMaps for BitMaps.BitMap;
    using Bytes32Address for address;

    /// @dev value is equal keccak256("SAFE_RECOVER_HEADER")
    bytes32 public constant SAFE_RECOVER_HEADER =
        0x556d79614195ebefcc31ab1ee514b9953934b87d25857902370689cbd29b49de;

    /// @dev value is equal keccak256("SAFE_TRANSFER")
    bytes32 public constant SAFE_TRANSFER_HEADER =
        0xc9627ddb76e5ee80829319617b557cc79498bbbc5553d8c632749a7511825f5d;

    ///@dev value is equal to keccak256("Permit(address token,address to,uint256 value,uint256 amount,uint256 nonce,uint256 deadline)")
    bytes32 private constant __PERMIT_TYPE_HASH =
        0x1d4e5c65da4048ea0e84458001171f3bf2f0666aa734d5dc971be326031829c5;

    uint256 public safeReceivedNativeBalance;
    mapping(address => uint256) public erc20Balances;
    mapping(address => BitMaps.BitMap) private __erc721Balances;
    mapping(address => mapping(uint256 => uint256)) public erc1155Balances;

    constructor(
        IAuthority authority_,
        string memory name_
    )
        payable
        onlyProxy
        Signable(name_, "1")
        Manager(
            address(authority_) == address(0)
                ? IAuthority(_msgSender())
                : authority_,
            Roles.TREASURER_ROLE
        )
    {
        safeReceivedNativeBalance = msg.value;
        emit BalanceInitiated(_msgSender(), msg.value);
    }

    receive() external payable virtual override {
        revert Treasury__MistakenTransfer();
    }

    fallback() external payable virtual override {
        if (msg.value == 0) revert Treasury__InvalidFunctionCall();
        if (_checkMesage(msg.data)) return;

        address operator = _msgSender();
        _checkBlacklist(operator);
        emit Received(operator, address(0), abi.encode(msg.value), msg.data);

        safeReceivedNativeBalance += msg.value;
    }

    function onERC1155Received(
        address operator_,
        address,
        uint256 id_,
        uint256 value_,
        bytes calldata data_
    ) external returns (bytes4) {
        if (value_ == 0 || data_.length == 0)
            revert Treasury__InvalidArgument();

        if (_checkMesage(data_))
            return IERC1155Receiver.onERC1155Received.selector;

        address token = _msgSender();
        _onlyProxy(token);
        _checkBlacklist(operator_);
        __checkInterface(token, type(IERC1155).interfaceId);

        erc1155Balances[token][id_] += value_;

        emit Received(operator_, token, abi.encode(id_, value_), data_);

        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator_,
        address,
        uint256[] calldata ids_,
        uint256[] calldata values_,
        bytes calldata data_
    ) external returns (bytes4) {
        uint256 length = ids_.length;
        if (length != values_.length) revert Treasury__LengthMismatch();
        if (_checkMesage(data_))
            return IERC1155Receiver.onERC1155BatchReceived.selector;

        address token = _msgSender();
        _onlyProxy(token);
        _checkBlacklist(operator_);
        __checkInterface(token, type(IERC1155).interfaceId);

        assembly {
            mstore(0, token)
            mstore(32, erc1155Balances.slot)
            mstore(32, keccak256(0, 64))
        }

        for (uint256 i; i < length; ) {
            assembly {
                let idx := shl(5, i)
                mstore(0, calldataload(add(ids_.offset, idx)))
                let key := keccak256(0, 64)
                sstore(
                    key,
                    add(calldataload(add(values_.offset, idx)), sload(key))
                )
                i := add(1, i)
            }
        }

        emit Received(operator_, token, abi.encode(ids_, values_), data_);

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address operator_,
        address,
        uint256 tokenId_,
        bytes calldata data_
    ) external override returns (bytes4) {
        if (_checkMesage(data_))
            return ERC721TokenReceiver.onERC721Received.selector;

        address token = _msgSender();
        _onlyProxy(token);
        _checkBlacklist(operator_);
        __checkInterface(token, type(IERC721).interfaceId);

        __erc721Balances[token].set(tokenId_);

        emit Received(operator_, token, abi.encode(tokenId_), data_);

        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function notifyERC20Transfer(
        address token_,
        uint256 value_,
        bytes calldata data_
    ) external virtual override onlyRole(Roles.PROXY_ROLE) returns (bytes4) {
        if (_checkMesage(data_))
            return IWithdrawable.notifyERC20Transfer.selector;

        if (value_ == 0) revert Treasury__InvalidArgument();
        if (
            token_ == address(0) ||
            token_ == address(this) ||
            token_.supportsInterface(type(IERC721).interfaceId) ||
            token_.supportsInterface(type(IERC1155).interfaceId)
        ) revert Treasury__InvalidTokenAddress();

        unchecked {
            erc20Balances[token_] += value_;
        }

        emit Received(
            abi.decode(data_, (address)),
            token_,
            abi.encode(value_),
            data_
        );

        return IWithdrawable.notifyERC20Transfer.selector;
    }

    function withdraw(
        address token_,
        address to_,
        uint256 value_,
        uint256 amount_, // if withdraw ERC1155
        uint256 deadline_,
        bytes calldata signature_
    ) external onlyEOA whenNotPaused {
        if (block.timestamp > deadline_) revert Treasury__Expired();

        _checkBlacklist(to_);

        if (
            !_hasRole(
                Roles.SIGNER_ROLE,
                _recoverSigner(
                    keccak256(
                        abi.encode(
                            __PERMIT_TYPE_HASH,
                            token_,
                            to_,
                            value_,
                            amount_,
                            _useNonce(to_.fillLast12Bytes()),
                            deadline_
                        )
                    ),
                    signature_
                )
            )
        ) revert Treasury__InvalidSignature();

        _withdraw(token_, to_, value_, abi.encode(amount_));
    }

    function withdraw(
        address token_,
        address to_,
        uint256 value_,
        bytes calldata data_
    ) external virtual override onlyRole(Roles.TREASURER_ROLE) {
        _withdraw(token_, to_, value_, data_);
    }

    function nonces(address account_) external view returns (uint256) {
        return _nonces[account_.fillLast12Bytes()];
    }

    function ownerOf(
        address token_,
        uint256 tokenId_
    ) external view returns (bool) {
        return __erc721Balances[token_].get(tokenId_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure virtual override returns (bool) {
        return
            interfaceId == type(ITreasury).interfaceId ||
            interfaceId == type(IWithdrawable).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function _withdraw(
        address token_,
        address to_,
        uint256 value_,
        bytes memory data_
    ) internal virtual {
        if (token_ == address(0)) {
            uint256 _balance = safeReceivedNativeBalance;
            if (value_ > _balance) revert Treasury__UnauthorizedWithdrawal();
            unchecked {
                _balance -= value_;
            }
            safeReceivedNativeBalance = _balance;

            _safeNativeTransfer(to_, value_);
        } else if (token_.supportsInterface(type(IERC721).interfaceId)) {
            if (!__erc721Balances[token_].get(value_))
                revert Treasury__UnauthorizedWithdrawal();

            __erc721Balances[token_].unset(value_);

            IERC721(token_).safeTransferFrom(
                address(this),
                to_,
                value_,
                "SAFE_WITHDRAW"
            );
        } else if (token_.supportsInterface(type(IERC1155).interfaceId)) {
            uint256 amount = abi.decode(data_, (uint256));
            bytes32 key;
            uint256 _balance;
            assembly {
                mstore(0, token_)
                mstore(32, erc1155Balances.slot)
                key := keccak256(0, 64)

                mstore(0, value_)
                mstore(32, key)
                key := keccak256(0, 64)
                _balance := sload(key)
            }
            if (_balance < amount) revert Treasury__UnauthorizedWithdrawal();

            assembly {
                sstore(key, sub(_balance, amount))
            }

            IERC1155(token_).safeTransferFrom(
                address(this),
                to_,
                value_,
                amount,
                "SAFE_WITHDRAW"
            );
        } else {
            bytes32 key;
            uint256 _balance;
            assembly {
                mstore(0, token_)
                mstore(32, erc20Balances.slot)
                key := keccak256(0, 64)

                _balance := sload(key)
            }

            if (value_ > _balance) revert Treasury__UnauthorizedWithdrawal();

            assembly {
                sstore(key, sub(_balance, value_))
            }

            _safeERC20Transfer(IERC20(token_), to_, value_);
        }

        emit Withdrawn(token_, to_, value_);
    }

    function _checkMesage(
        bytes memory data_
    ) internal view virtual returns (bool) {
        bytes32 header = abi.decode(data_, (bytes32));

        if (header == SAFE_RECOVER_HEADER) return true;
        if (header != SAFE_TRANSFER_HEADER) revert Treasury__MistakenTransfer();

        return false;
    }

    function __checkInterface(
        address token_,
        bytes4 interfaceId_
    ) private view {
        if (!token_.supportsInterface(interfaceId_))
            revert Treasury__InvalidFunctionCall();
    }
}
