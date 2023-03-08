// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReentrancyGuard} from "../oz/security/ReentrancyGuard.sol";

import {CommandGate} from "../internal/CommandGate.sol";
import {Roles, IAuthority, Manager} from "./base/Manager.sol";

import {IFundForwarder} from "../internal/FundForwarder.sol";
import {
    IERC20,
    IERC20Permit
} from "../oz/token/ERC20/extensions/IERC20Permit.sol";
import {IERC721, ERC721TokenReceiver} from "../oz/token/ERC721/ERC721.sol";
import {IWithdrawable} from "../internal/interfaces/IWithdrawable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; //  TODO: update oz-custom import
import {
    IERC1155Receiver
} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Permit} from "../oz/token/ERC721/extensions/IERC721Permit.sol";

import {
    ICommandGate,
    IUniversalCommandGate
} from "./interfaces/IUniversalCommandGate.sol";

import {SigUtil} from "../libraries/SigUtil.sol";

import {
    IERC165,
    ERC165Checker
} from "../oz/utils/introspection/ERC165Checker.sol";

contract UniversalCommandGate is
    Manager,
    CommandGate,
    ReentrancyGuard,
    IERC1155Receiver,
    ERC721TokenReceiver,
    IUniversalCommandGate
{
    using SigUtil for bytes;
    using ERC165Checker for address;

    constructor(
        IAuthority authority_,
        address[] memory vaults_
    ) payable ReentrancyGuard() Manager(authority_, 0) CommandGate(vaults_) {}

    function changeVault(
        address vault_
    ) external onlyRole(Roles.TREASURER_ROLE) {
        _changeVault(vault_);
    }

    function whitelistVaults(
        address[] calldata vaults_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        _whitelistVaults(vaults_);
    }

    function whitelistTarget(
        address target_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        _whitelistTarget(target_);
    }

    function _handleDeposit(
        address operator_,
        address mainVault_,
        Asset calldata asset_,
        Command calldata command_
    ) internal override {
        // handle deposit logic
        if (asset_.token == address(0))
            _handleNativeDeposit(command_.vault, operator_, asset_);
        else if (asset_.token.supportsInterface(type(IERC721).interfaceId))
            _handleERC721Deposit(command_.vault, asset_);
        else if (asset_.token.supportsInterface(type(IERC1155).interfaceId)) {
            if (asset_.extraData.length == 32) {
                _handleERC1155Deposit(
                    // amount
                    abi.decode(asset_.extraData, (uint256)),
                    command_.vault,
                    asset_
                );
            } else {
                (uint256[] memory ids, uint256[] memory amounts) = abi.decode(
                    asset_.extraData,
                    (uint256[], uint256[])
                );

                _handleERC1155BatchDeposit(
                    command_.vault,
                    asset_,
                    ids,
                    amounts
                );
            }
        } else _handleERC20Deposit(command_.vault, mainVault_, asset_);
    }

    function onERC721Received(
        address operator_,
        address from_,
        uint256 tokenId_,
        bytes calldata data_
    ) external override whenNotPaused returns (bytes4) {
        bytes memory emptyBytes = "";
        Command memory command = abi.decode(data_, (Command));
        Asset memory asset = Asset({
            token: _msgSender(),
            account: from_,
            value: tokenId_,
            deadline: 0,
            signature: emptyBytes,
            extraData: emptyBytes
        });

        _beforeDeposit({
            eoaCheck_: false,
            operator_: operator_,
            mainVault_: vault(),
            asset_: asset,
            command_: command,
            extraData_: emptyBytes
        });
        _handleERC721Deposit(command.vault, asset);
        _afterDeposit(operator_, asset, command, emptyBytes);

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator_,
        address from_,
        uint256 id_,
        uint256 value_,
        bytes calldata data_
    ) external override returns (bytes4) {
        bytes memory emptyBytes = "";
        Command memory command = abi.decode(data_, (Command));
        Asset memory asset = Asset({
            token: _msgSender(),
            account: from_,
            value: id_,
            deadline: 0,
            signature: emptyBytes,
            extraData: abi.encode(value_)
        });

        _handleERC1155Deposit(value_, command.vault, asset);
        _afterDeposit(operator_, asset, command, emptyBytes);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator_,
        address from_,
        uint256[] calldata ids_,
        uint256[] calldata values_,
        bytes calldata data_
    ) external override returns (bytes4) {
        bytes memory emptyBytes = "";
        Command memory command = abi.decode(data_, (Command));
        Asset memory asset = Asset({
            token: _msgSender(),
            account: from_,
            value: 0,
            deadline: 0,
            signature: emptyBytes,
            extraData: emptyBytes
        });

        _handleERC1155BatchDeposit(command.vault, asset, ids_, values_);
        _afterDeposit(operator_, asset, command, emptyBytes);

        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(
        bytes4 interfaceId_
    ) external pure override returns (bool) {
        return
            interfaceId_ == type(IERC165).interfaceId ||
            interfaceId_ == type(ICommandGate).interfaceId ||
            interfaceId_ == type(IERC1155Receiver).interfaceId ||
            interfaceId_ == type(ERC721TokenReceiver).interfaceId ||
            interfaceId_ == type(IUniversalCommandGate).interfaceId;
    }

    function safeRecoverHeader() public pure override returns (bytes memory) {
        /// @dev value is equal keccak256("SAFE_RECOVER_HEADER")
        return
            bytes.concat(
                bytes32(
                    0x556d79614195ebefcc31ab1ee514b9953934b87d25857902370689cbd29b49de
                )
            );
    }

    function safeTransferHeader() public pure override returns (bytes memory) {
        /// @dev value is equal keccak256("SAFE_TRANSFER")
        return
            bytes.concat(
                bytes32(
                    0xc9627ddb76e5ee80829319617b557cc79498bbbc5553d8c632749a7511825f5d
                )
            );
    }

    function _handleERC20Deposit(
        address vault_,
        address mainVault_,
        Asset calldata asset_
    ) internal virtual {
        if (
            IERC20(asset_.token).allowance(asset_.account, address(this)) <
            asset_.value
        ) {
            (bytes32 r, bytes32 s, uint8 v) = asset_.signature.split();
            IERC20Permit(asset_.token).permit(
                asset_.account,
                address(this),
                asset_.value,
                asset_.deadline,
                v,
                r,
                s
            );
        }

        _safeERC20TransferFrom(
            IERC20(asset_.token),
            asset_.account,
            vault_,
            asset_.value
        );

        if (vault_ != mainVault_) return;
        if (
            IWithdrawable(vault_).notifyERC20Transfer(
                asset_.token,
                asset_.value,
                safeTransferHeader()
            ) != IWithdrawable.notifyERC20Transfer.selector
        ) revert UniversalCommandGate__ExecutionFailed();
    }

    function _handleERC721Deposit(
        address vault_,
        Asset memory asset_
    ) internal virtual {
        if (
            !(IERC721(asset_.token).ownerOf(asset_.value) == address(this) ||
                IERC721(asset_.token).getApproved(asset_.value) ==
                address(this))
        )
            IERC721Permit(asset_.token).permit(
                address(this),
                asset_.value,
                asset_.deadline,
                asset_.signature
            );

        IERC721(asset_.token).safeTransferFrom(
            asset_.account,
            vault_,
            asset_.value,
            safeTransferHeader()
        );
    }

    function _handleERC1155Deposit(
        uint256 amount_,
        address vault_,
        Asset memory asset_
    ) internal virtual {
        IERC1155(asset_.token).safeTransferFrom(
            asset_.account,
            vault_,
            asset_.value,
            amount_,
            safeTransferHeader()
        );
    }

    function _handleERC1155BatchDeposit(
        address vault_,
        Asset memory asset_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) internal virtual {
        IERC1155(asset_.token).safeBatchTransferFrom(
            asset_.account,
            vault_,
            ids_,
            amounts_,
            safeTransferHeader()
        );
    }

    function _handleNativeDeposit(
        address vault_,
        address operator_,
        Asset calldata asset_
    ) internal virtual {
        _safeNativeTransfer(vault_, asset_.value, safeTransferHeader());

        uint256 refund = msg.value - asset_.value;
        if (refund == 0) return;

        _safeNativeTransfer(operator_, refund, "");
        emit Refunded(operator_, refund);
    }

    function _checkSender(
        bool eoaCheck_,
        address account_,
        Asset memory asset_,
        bytes memory
    ) internal view virtual override {
        if (account_ == asset_.account) {
            _checkBlacklist(account_);

            if (!eoaCheck_) return;
            _onlyEOA(account_);
        } else _checkRole(Roles.PROXY_ROLE, account_);
    }

    function _beforeRecover(
        bytes memory
    ) internal view override whenPaused onlyRole(Roles.OPERATOR_ROLE) {}

    function _afterRecover(
        address,
        address,
        uint256,
        bytes memory
    ) internal override {}
}
