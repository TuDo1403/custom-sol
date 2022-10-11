// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "../../utils/ContextUpgradeable.sol";

import "./IERC20Upgradeable.sol";
import "../../../libraries/Bytes32Address.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20Upgradeable is ContextUpgradeable, IERC20Upgradeable {
    using Bytes32Address for address;

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint256 public decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(bytes32 => uint256) internal _balanceOf;

    mapping(bytes32 => mapping(bytes32 => uint256)) internal _allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function __ERC20_init(
        string memory name_,
        string memory symbol_,
        uint256 decimals_
    ) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC20_init_unchained(
        string memory name_,
        string memory symbol_,
        uint256 decimals_
    ) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        decimals = decimals_ & ~uint8(0);
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        address sender = _msgSender();
        _allowance[sender.fillLast12Bytes()][
            spender.fillLast12Bytes()
        ] = amount;

        emit Approval(sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        address sender = _msgSender();
        _beforeTokenTransfer(sender, to, amount);
        _balanceOf[sender.fillLast12Bytes()] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to.fillLast12Bytes()] += amount;
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

        bytes32 _from = from.fillLast12Bytes();
        _spendAllowance(_from, _msgSender().fillLast12Bytes(), amount);

        _balanceOf[_from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to.fillLast12Bytes()] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
        return true;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balanceOf[account.fillLast12Bytes()];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowance[owner.fillLast12Bytes()][spender.fillLast12Bytes()];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    function _spendAllowance(
        bytes32 owner_,
        bytes32 spender_,
        uint256 amount_
    ) internal virtual {
        uint256 allowed = _allowance[owner_][spender_]; // Saves gas for limited approvals.
        if (allowed != ~uint256(0))
            _allowance[owner_][spender_] = allowed - amount_;
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
            _balanceOf[to.fillLast12Bytes()] += amount;
        }

        emit Transfer(address(0), to, amount);

        _afterTokenTransfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        _balanceOf[from.fillLast12Bytes()] -= amount;

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
