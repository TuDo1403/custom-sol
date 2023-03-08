// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FundForwarder, IFundForwarder} from "./FundForwarder.sol";

import {ICommandGate} from "./interfaces/ICommandGate.sol";

import {BitMaps} from "../oz/utils/structs/BitMaps.sol";
import {ErrorHandler} from "../libraries/ErrorHandler.sol";
import {Bytes32Address} from "../libraries/Bytes32Address.sol";

abstract contract CommandGate is ICommandGate, FundForwarder {
    using ErrorHandler for bool;
    using Bytes32Address for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private __isWhitelisted;
    BitMaps.BitMap private __whitelistedVaults;

    constructor(address[] memory vaults_) payable {
        _whitelistVaults(vaults_);
    }

    function depositWithCommand(
        Asset calldata asset_,
        Command calldata command_
    ) external payable virtual {
        address mainVault = vault();
        address operator = _msgSender();
        bytes memory emptyBytes = "";

        _beforeDeposit({
            eoaCheck_: true,
            operator_: operator,
            mainVault_: mainVault,
            asset_: asset_,
            command_: command_,
            extraData_: emptyBytes
        });

        // handle deposit logic
        _handleDeposit(operator, mainVault, asset_, command_);

        _afterDeposit(operator, asset_, command_, emptyBytes);
    }

    function isVaultWhitelisted(
        address addr_
    ) external view virtual returns (bool) {
        return __whitelistedVaults.get(addr_.fillLast96Bits());
    }

    function isTargetWhitelisted(
        address addr_
    ) external view virtual returns (bool) {
        return __isWhitelisted.get(addr_.fillLast96Bits());
    }

    function _handleDeposit(
        address operator_,
        address mainVault_,
        Asset calldata asset_,
        Command calldata command_
    ) internal virtual;

    function _beforeDeposit(
        bool eoaCheck_,
        address operator_,
        address mainVault_,
        Asset memory asset_,
        Command memory command_,
        bytes memory extraData_
    ) internal virtual {
        _checkSender(eoaCheck_, operator_, asset_, extraData_);
        _checkCommand(mainVault_, command_, extraData_);
    }

    function _afterDeposit(
        address operator_,
        Asset memory asset_,
        Command memory command_,
        bytes memory
    ) internal virtual {
        _executeCommand(
            command_.target,
            command_.fnSig,
            _concatDepositData(
                asset_.account,
                asset_.token,
                asset_.value,
                asset_.extraData,
                command_.arguments
            )
        );

        emit Commanded(operator_, asset_, command_);
    }

    function _checkSender(
        bool eoaCheck_,
        address account_,
        Asset memory asset_,
        bytes memory
    ) internal view virtual;

    function _checkCommand(
        address mainVault_,
        Command memory command_,
        bytes memory
    ) internal view virtual {
        // check target external call
        if (!__isWhitelisted.get(command_.target.fillLast96Bits()))
            revert CommandGate__UnknownAddress();

        // check asset vault
        if (
            !(command_.vault == mainVault_ ||
                __whitelistedVaults.get(command_.vault.fillLast96Bits()))
        ) revert CommandGate__UnknownAddress();
    }

    function _executeCommand(
        address target_,
        bytes4 fnSignature_,
        bytes memory params_
    ) internal virtual {
        (bool ok, bytes memory returnOrRevertData) = target_.call(
            abi.encodePacked(fnSignature_, params_)
        );
        ok.handleRevertIfNotSuccess(returnOrRevertData);
    }

    function _concatDepositData(
        address account_,
        address token_,
        uint256 value_,
        bytes memory extraData_,
        bytes memory data_
    ) internal pure virtual returns (bytes memory) {
        assembly {
            mstore(add(data_, 0x20), account_)
            mstore(add(data_, 0x40), token_)
            mstore(add(data_, 0x60), value_)
            let length := mload(extraData_)
            if iszero(iszero(length)) {
                calldatacopy(
                    add(data_, 0x80),
                    add(extraData_, 0x20),
                    shr(3, length)
                )
            }
        }
        return data_;
    }

    function _whitelistTarget(address target_) internal virtual {
        if (
            target_ == address(0) ||
            target_ == address(this) ||
            !_isProxy(target_) ||
            target_ == vault()
        ) revert CommandGate__InvalidArgument();

        __isWhitelisted.set(target_.fillLast96Bits());

        emit Whitelisted(_msgSender(), target_);
    }

    function _whitelistVaults(address[] memory vaults_) internal virtual {
        uint256[] memory uintVaults;
        assembly {
            uintVaults := vaults_
        }

        uint256 length = uintVaults.length;
        for (uint256 i; i < length; ) {
            if (uintVaults[i] == 0 || vaults_[i] == address(this))
                revert CommandGate__InvalidArgument();

            __whitelistedVaults.set(uintVaults[i]);

            unchecked {
                ++i;
            }
        }

        emit VaultsWhitelisted(_msgSender(), vaults_);
    }
}
