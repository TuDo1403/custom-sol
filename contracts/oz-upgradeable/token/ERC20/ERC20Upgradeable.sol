// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
    ERC165Upgradeable,
    IERC165Upgradeable
} from "../../utils/introspection/ERC165Upgradeable.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";

import {
    IERC20MetadataUpgradeable
} from "./extensions/IERC20MetadataUpgradeable.sol";
import {IERC20Upgradeable} from "./IERC20Upgradeable.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20Upgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    uint8 public decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    string public name;

    string public symbol;

    mapping(address => uint256) internal _balanceOf;

    mapping(address => mapping(address => uint256)) internal _allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function __ERC20_init(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC20_init_unchained(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        address sender = _msgSender();

        assembly {
            mstore(0, sender)
            mstore(32, _allowance.slot)
            mstore(32, keccak256(0, 64))
            mstore(0, spender)
            sstore(keccak256(0, 64), amount)
        }

        emit Approval(sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address sender = _msgSender();
        _beforeTokenTransfer(sender, to, amount);
        _balanceOf[sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(sender, to, amount);

        _afterTokenTransfer(sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);

        _spendAllowance(from, _msgSender(), amount);

        _balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == type(IERC20Upgradeable).interfaceId || // ERC165 Interface ID for ERC20
            interfaceId == type(IERC20MetadataUpgradeable).interfaceId; // ERC165 Interface ID for ERC20Metadata
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balanceOf[account];
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowance[owner][spender];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        bytes32 allowanceKey;
        uint256 allowed;
        assembly {
            mstore(0, owner_)
            mstore(32, _allowance.slot)
            mstore(32, keccak256(0, 64))
            mstore(0, spender_)
            allowanceKey := keccak256(0, 64)
            allowed := sload(allowanceKey)
        }

        if (allowed == ~uint256(0)) return;

        allowed -= amount_;
        assembly {
            sstore(allowanceKey, allowed)
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);

        _afterTokenTransfer(address(0), to, amount);

        _afterTokenTransfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        _balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);

        _afterTokenTransfer(from, address(0), amount);
    }

    uint256[44] private __gap;
}
