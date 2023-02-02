// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/ContextUpgradeable.sol";

import "./TransferableUpgradeable.sol";

import "./interfaces/IFundForwarderUpgradeable.sol";

/**
 * @title FundForwarderUpgradeable
 * @dev Abstract contract for forwarding funds to a specified address.
 */
abstract contract FundForwarderUpgradeable is
    ContextUpgradeable,
    TransferableUpgradeable,
    IFundForwarderUpgradeable
{
    /**
     * @dev Address to forward funds to
     */
    bytes32 private __vault;

    /**
     * @dev Receives funds and forwards them to the vault address
     */
    receive() external payable virtual {
        address _vault = vault();

        (bool ok, ) = _vault.call{value: msg.value}(safeRecoverHeader());
        if (!ok) revert FundForwarder__ForwardFailed();

        emit Forwarded(_msgSender(), msg.value);

        _afterRecover(_vault, address(0), abi.encode(msg.value));
    }

    function __FundForwarder_init(address vault_) internal onlyInitializing {
        __FundForwarder_init_unchained(vault_);
    }

    function __FundForwarder_init_unchained(
        address vault_
    ) internal onlyInitializing {
        _changeVault(vault_);
    }

    /// @inheritdoc IFundForwarderUpgradeable
    function recoverERC20(IERC20Upgradeable token_, uint256 amount_) external {
        __checkValidAddress(address(token_));
        address _vault = vault();

        _safeERC20Transfer(token_, _vault, amount_);

        emit Recovered(_msgSender(), address(token_), amount_);

        _afterRecover(_vault, address(token_), abi.encode(amount_));
    }

    /// @inheritdoc IFundForwarderUpgradeable
    function recoverNFT(IERC721Upgradeable token_, uint256 tokenId_) external {
        __checkValidAddress(address(token_));
        address _vault = vault();

        token_.safeTransferFrom(
            address(this),
            _vault,
            tokenId_,
            safeRecoverHeader()
        );

        emit Recovered(_msgSender(), address(token_), tokenId_);

        _afterRecover(_vault, address(token_), abi.encode(tokenId_));
    }

    /// @inheritdoc IFundForwarderUpgradeable
    function recoverNFTs(IERC721EnumerableUpgradeable token_) external {
        __checkValidAddress(address(token_));
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

        emit RecoveredMulti(_msgSender(), address(token_), tokenIds);
    }

    /// @inheritdoc IFundForwarderUpgradeable
    function recoverNative() external {
        address _vault = vault();

        uint256 balance = address(this).balance;

        _safeNativeTransfer(_vault, address(this).balance);

        _afterRecover(_vault, address(0), abi.encode(balance));
    }

    function vault() public view returns (address vault_) {
        assembly {
            vault_ := sload(__vault.slot)
        }

        __checkValidAddress(vault_);
    }

    /**
     * @dev Changes the vault address
     * @param vault_ New vault address
     */
    function _changeVault(address vault_) internal {
        __checkValidAddress(vault_);

        emit VaultUpdated(vault(), vault_);

        assembly {
            sstore(__vault.slot, vault_)
        }
    }

    function safeRecoverHeader() public pure virtual returns (bytes memory);

    function safeTransferHeader() public pure virtual returns (bytes memory);

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
    function __checkValidAddress(address addr_) private view {
        if (addr_ == address(0) || addr_ == address(this))
            revert FundForwarder__InvalidArgument();
    }

    uint256[49] private __gap;
}
