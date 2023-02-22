// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";

import {Transferable} from "./Transferable.sol";
import {ProxyChecker} from "./ProxyChecker.sol";

import {
    IERC20,
    IERC721,
    IFundForwarder,
    IERC721Enumerable
} from "./interfaces/IFundForwarder.sol";

/**
 * @title FundForwarder
 * @dev Abstract contract for forwarding funds to a specified address.
 */
abstract contract FundForwarder is
    Context,
    ProxyChecker,
    Transferable,
    IFundForwarder
{
    /**
     * @dev Address to forward funds to
     */
    bytes32 private __vault;

    /**
     * @dev Constructor that sets the vault address
     * @param vault_ Address to forward funds to
     */
    constructor(address vault_) payable {
        _changeVault(vault_);
    }

    /**
     * @dev Receives funds and forwards them to the vault address
     */
    receive() external payable virtual onlyEOA {
        _beforeRecover("");
        address _vault = vault();

        _safeNativeTransfer(_vault, msg.value, safeRecoverHeader());

        emit Forwarded(_msgSender(), msg.value);

        _afterRecover(_vault, address(0), abi.encode(msg.value));
    }

    /// @inheritdoc IFundForwarder
    function recoverERC20(IERC20 token_, uint256 amount_) external virtual {
        _beforeRecover("");
        __checkValidAddress(address(token_));
        address sender = _msgSender();
        _onlyEOA(sender);

        address _vault = vault();

        _safeERC20Transfer(token_, _vault, amount_);

        emit Recovered(sender, address(token_), amount_);

        _afterRecover(_vault, address(token_), abi.encode(amount_));
    }

    /// @inheritdoc IFundForwarder
    function recoverNFT(IERC721 token_, uint256 tokenId_) external virtual {
        _beforeRecover("");
        __checkValidAddress(address(token_));
        address sender = _msgSender();
        _onlyEOA(sender);
        address _vault = vault();

        token_.safeTransferFrom(
            address(this),
            _vault,
            tokenId_,
            safeRecoverHeader()
        );

        emit Recovered(sender, address(token_), tokenId_);

        _afterRecover(_vault, address(token_), abi.encode(tokenId_));
    }

    /// @inheritdoc IFundForwarder
    function recoverNFTs(IERC721Enumerable token_) external virtual {
        _beforeRecover("");
        __checkValidAddress(address(token_));
        address sender = _msgSender();
        _onlyEOA(sender);

        address _vault = vault();
        uint256 length = token_.balanceOf(address(this));
        uint256[] memory tokenIds = new uint256[](length);
        bytes memory recoverHeader = safeRecoverHeader();
        for (uint256 i; i < length; ) {
            token_.safeTransferFrom(
                address(this),
                _vault,
                tokenIds[i] = token_.tokenOfOwnerByIndex(address(this), i),
                recoverHeader
            );

            unchecked {
                ++i;
            }
        }

        _afterRecover(_vault, address(token_), abi.encode(tokenIds));

        emit RecoveredMulti(sender, address(token_), tokenIds);
    }

    /// @inheritdoc IFundForwarder
    function recoverNative() external virtual {
        _beforeRecover("");
        address sender = _msgSender();
        _onlyEOA(sender);

        address _vault = vault();
        uint256 balance = address(this).balance;
        _safeNativeTransfer(_vault, balance, safeRecoverHeader());

        emit Recovered(sender, address(0), balance);

        _afterRecover(_vault, address(0), abi.encode(balance));
    }

    function vault() public view virtual returns (address vault_) {
        assembly {
            vault_ := sload(__vault.slot)
        }

        __checkValidAddress(vault_);
    }

    function safeRecoverHeader() public pure virtual returns (bytes memory);

    function safeTransferHeader() public pure virtual returns (bytes memory);

    /**
     * @dev Changes the vault address
     * @param vault_ New vault address
     */
    function _changeVault(address vault_) internal virtual {
        __checkValidAddress(vault_);

        address old;
        assembly {
            old := sload(__vault.slot)
        }
        emit VaultUpdated(old, vault_);

        assembly {
            sstore(__vault.slot, vault_)
        }
    }

    function _beforeRecover(bytes memory data_) internal virtual;

    function _afterRecover(
        address vault_,
        address token_,
        bytes memory value_
    ) internal virtual;

    /**
     *@dev Asserts that the given address is not the zero address
     *@param addr_ The address to check
     *@custom:throws FundForwarder__InvalidArgument if the address is the zero address
     */
    function __checkValidAddress(address addr_) private view {
        if (addr_ == address(0) || addr_ == address(this))
            revert FundForwarder__InvalidArgument();
    }
}
