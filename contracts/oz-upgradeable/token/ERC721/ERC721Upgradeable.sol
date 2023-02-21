// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {
    ERC165Upgradeable,
    IERC165Upgradeable
} from "../../utils/introspection/ERC165Upgradeable.sol";

import {IERC721Upgradeable} from "./IERC721Upgradeable.sol";
import {
    IERC721MetadataUpgradeable
} from "./extensions/IERC721MetadataUpgradeable.sol";

import {Bytes32Address} from "../../../libraries/Bytes32Address.sol";
import {BitMapsUpgradeable} from "../../utils/structs/BitMapsUpgradeable.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721Upgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using Bytes32Address for *;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    function _baseURI() internal view virtual returns (string memory);

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bytes32) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;

    function ownerOf(
        uint256 id
    ) public view virtual override returns (address owner) {
        assembly {
            mstore(0, id)
            mstore(32, _ownerOf.slot)
            owner := sload(keccak256(0, 64))
        }

        if (owner == address(0)) revert ERC721__NotMinted();
    }

    function balanceOf(
        address owner
    ) public view virtual returns (uint256 balance_) {
        if (owner == address(0)) revert ERC721__NonZeroAddress();

        assembly {
            mstore(0, owner)
            mstore(32, _balanceOf.slot)
            balance_ := sload(keccak256(0, 64))
        }
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bytes32) internal _getApproved;

    mapping(address => BitMapsUpgradeable.BitMap) internal _isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(
        string calldata name_,
        string calldata symbol_
    ) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32)
            revert ERC721__StringTooLong();
        name = name_;
        symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner;
        assembly {
            mstore(0, id)
            mstore(32, _ownerOf.slot)
            owner := sload(keccak256(0, 64))
        }

        address sender = _msgSender();
        if (
            !(sender == owner ||
                _isApprovedForAll[owner].get(sender.fillLast96Bits()))
        ) revert ERC721__Unauthorized();

        assembly {
            //mstore(0, id)
            mstore(32, _getApproved.slot)
            sstore(keccak256(0, 64), spender)
        }

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual {
        address sender = _msgSender();

        _isApprovedForAll[sender].setTo(operator.fillLast96Bits(), approved);

        emit ApprovalForAll(sender, operator, approved);
    }

    function getApproved(
        uint256 tokenId
    ) external view override returns (address operator) {
        return _getApproved[tokenId].fromFirst20Bytes();
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {
        return _isApprovedForAll[owner].get(operator.fillLast96Bits());
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return
            (spender == owner ||
                _getApproved[tokenId] == spender.fillLast12Bytes()) ||
            _isApprovedForAll[owner].get(spender.fillLast96Bits());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (to == address(0)) revert ERC721__InvalidRecipient();

        bytes32 ownerOfKey;
        address owner;
        assembly {
            mstore(0, id)
            mstore(32, _ownerOf.slot)
            ownerOfKey := keccak256(0, 64)
            owner := sload(ownerOfKey)
        }
        if (from != owner) revert ERC721__WrongFrom();

        _beforeTokenTransfer(from, to, id);

        address sender = _msgSender();
        if (
            !(sender == from ||
                sender.fillLast12Bytes() == _getApproved[id] ||
                _isApprovedForAll[from].get(sender.fillLast96Bits()))
        ) revert ERC721__Unauthorized();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            ++_balanceOf[to];
            --_balanceOf[from];
        }

        assembly {
            sstore(ownerOfKey, to)
        }
        delete _getApproved[id];

        emit Transfer(from, to, id);

        _afterTokenTransfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            !(to.code.length == 0 ||
                ERC721TokenReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiverUpgradeable.onERC721Received.selector)
        ) revert ERC721__UnsafeRecipient();
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (to == address(0)) revert ERC721__InvalidRecipient();

        address owner;
        bytes32 key;
        assembly {
            mstore(0, tokenId)
            mstore(32, _ownerOf.slot)
            key := keccak256(0, 64)
            owner := sload(key)
        }
        if (from != owner) revert ERC721__WrongFrom();

        _beforeTokenTransfer(from, to, tokenId);

        unchecked {
            ++_balanceOf[to];
            --_balanceOf[from];
        }

        assembly {
            sstore(key, to)
        }

        delete _getApproved[tokenId];

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);
        if (
            !(to.code.length == 0 ||
                ERC721TokenReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiverUpgradeable.onERC721Received.selector)
        ) revert ERC721__UnsafeRecipient();
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert ERC721__InvalidRecipient();

        bytes32 key;
        bytes32 owner;
        assembly {
            mstore(0, id)
            mstore(32, _ownerOf.slot)
            key := keccak256(0, 64)
            owner := sload(key)
        }
        if (owner != 0) revert ERC721__AlreadyMinted();

        _beforeTokenTransfer(address(0), to, id);

        // Counter overflow is incredibly unrealistic.
        unchecked {
            ++_balanceOf[to];
        }

        assembly {
            sstore(key, to)
        }

        emit Transfer(address(0), to, id);

        _afterTokenTransfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        bytes32 key;
        address owner;
        assembly {
            mstore(0, id)
            mstore(32, _ownerOf.slot)
            key := keccak256(0, 64)
            owner := sload(key)
        }
        if (owner == address(0)) revert ERC721__NotMinted();

        _beforeTokenTransfer(owner, address(0), id);

        // Ownership check above ensures no underflow.
        unchecked {
            --_balanceOf[owner];
        }
        assembly {
            sstore(key, 0)
        }
        delete _getApproved[id];

        emit Transfer(owner, address(0), id);

        _afterTokenTransfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            !(to.code.length == 0 ||
                ERC721TokenReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    address(0),
                    id,
                    ""
                ) ==
                ERC721TokenReceiverUpgradeable.onERC721Received.selector)
        ) revert ERC721__UnsafeRecipient();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);
        if (
            !(to.code.length == 0 ||
                ERC721TokenReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiverUpgradeable.onERC721Received.selector)
        ) revert ERC721__UnsafeRecipient();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiverUpgradeable {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiverUpgradeable.onERC721Received.selector;
    }
}
