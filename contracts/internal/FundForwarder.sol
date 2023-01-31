// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Context.sol";

import "./Transferable.sol";

import "./interfaces/IFundForwarder.sol";

/**
 * @title FundForwarder
 * @dev Abstract contract for forwarding funds to a specified address.
 */
abstract contract FundForwarder is Context, Transferable, IFundForwarder {
    /**
     * @dev Address to forward funds to
     */
    address public vault;

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
    receive() external payable virtual {
        address _vault = vault;
        __nonZeroAddress(_vault);

        (bool ok, ) = _vault.call{value: msg.value}("forward");
        if (!ok) revert FundForwarder__ForwardFailed();

        emit Forwarded(_msgSender(), msg.value);

        _afterRecover(_vault, address(0), abi.encode(msg.value));
    }

    function changeVault(address vault_) external virtual;

    /// @inheritdoc IFundForwarder
    function recoverERC20(IERC20 token_, uint256 amount_) external {
        address _vault = vault;
        __nonZeroAddress(_vault);

        _safeERC20Transfer(token_, _vault, amount_);

        emit Recovered(_msgSender(), address(token_), amount_);

        _afterRecover(_vault, address(token_), abi.encode(amount_));
    }

    /// @inheritdoc IFundForwarder
    function recoverNFT(IERC721 token_, uint256 tokenId_) external {
        address _vault = vault;
        __nonZeroAddress(_vault);

        token_.safeTransferFrom(address(this), _vault, tokenId_);

        emit Recovered(_msgSender(), address(token_), tokenId_);

        _afterRecover(_vault, address(token_), abi.encode(tokenId_));
    }

    /// @inheritdoc IFundForwarder
    function recoverNFTs(IERC721Enumerable token_) external {
        uint256 length = token_.balanceOf(address(this));
        uint256[] memory tokenIds = new uint256[](length);
        address _vault = vault;
        for (uint256 i; i < length; ) {
            token_.safeTransferFrom(
                address(this),
                _vault,
                tokenIds[i] = token_.tokenOfOwnerByIndex(address(this), i)
            );

            unchecked {
                ++i;
            }
        }

        _afterRecover(_vault, address(token_), abi.encode(tokenIds));

        emit RecoveredMulti(_msgSender(), address(token_), tokenIds);
    }

    /// @inheritdoc IFundForwarder
    function recoverNative() external {
        address _vault = vault;
        __nonZeroAddress(_vault);
        uint256 balance = address(this).balance;
        _safeNativeTransfer(_vault, balance);

        emit Recovered(_msgSender(), address(0), balance);

        _afterRecover(_vault, address(0), abi.encode(balance));
    }

    /**
     * @dev Changes the vault address
     * @param vault_ New vault address
     */
    function _changeVault(address vault_) internal {
        __nonZeroAddress(vault_);

        emit VaultUpdated(vault, vault_);

        vault = vault_;
    }

    function _afterRecover(
        address vault_,
        address token_,
        bytes memory value_
    ) internal virtual {}

    /**
     *@dev Asserts that the given address is not the zero address
     *@param addr_ The address to check
     *@custom:throws FundForwarder__InvalidArgument if the address is the zero address
     */
    function __nonZeroAddress(address addr_) private pure {
        if (addr_ == address(0)) revert FundForwarder__InvalidArgument();
    }
}
