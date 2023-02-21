// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Context} from "../../utils/Context.sol";

import {IERC1155} from "./IERC1155.sol";

import {Bytes32Address} from "../../../libraries/Bytes32Address.sol";
import {BitMaps} from "../../utils/structs/BitMaps.sol";

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 is Context, IERC1155 {
    using BitMaps for BitMaps.BitMap;
    using Bytes32Address for address;

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/
    string private __uri;

    mapping(address => BitMaps.BitMap) internal _isApprovedForAll;

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/
    // constructor(string memory uri_) payable {
    //     _setURI(uri_);
    // }

    function uri(uint256) public view virtual returns (string memory) {
        return __uri;
    }

    function isApprovedForAll(
        address owner_,
        address operator_
    ) external view returns (bool) {
        return _isApprovedForAll[owner_].get(operator_.fillLast96Bits());
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual {
        address sender = _msgSender();

        _isApprovedForAll[sender].setTo(operator.fillLast96Bits(), approved);

        emit ApprovalForAll(sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        address sender = _msgSender();
        if (
            !(sender == from ||
                _isApprovedForAll[from].get(sender.fillLast96Bits()))
        ) revert ERC1155__Unauthorized();

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(sender, from, to, id, amount);

        if (
            (to == address(0) || to.code.length != 0) &&
            ERC1155TokenReceiver(to).onERC1155Received(
                sender,
                from,
                id,
                amount,
                data
            ) !=
            ERC1155TokenReceiver.onERC1155Received.selector
        ) revert ERC1155__UnsafeRecipient();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        uint256 length = ids.length;
        if (length != amounts.length) revert ERC1155__LengthMismatch();

        address sender = _msgSender();
        if (
            !(sender == from ||
                _isApprovedForAll[from].get(sender.fillLast96Bits()))
        ) revert ERC1155__Unauthorized();

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;
        for (uint256 i; i < length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(sender, from, to, ids, amounts);

        if (
            (to == address(0) || to.code.length != 0) &&
            ERC1155TokenReceiver(to).onERC1155BatchReceived(
                sender,
                from,
                ids,
                amounts,
                data
            ) !=
            ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert ERC1155__UnsafeRecipient();
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
        uint256 length = owners.length;
        if (length != ids.length) revert ERC1155__LengthMismatch();

        balances = new uint256[](length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.

        for (uint256 i; i < length; ) {
            balances[i] = balanceOf[owners[i]][ids[i]];
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    function _setURI(string memory newURI_) internal virtual {
        __uri = newURI_;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;
        address sender = _msgSender();
        emit TransferSingle(sender, address(0), to, id, amount);

        if (
            (to == address(0) || to.code.length != 0) &&
            ERC1155TokenReceiver(to).onERC1155Received(
                sender,
                address(0),
                id,
                amount,
                data
            ) !=
            ERC1155TokenReceiver.onERC1155Received.selector
        ) revert ERC1155__UnsafeRecipient();
    }

    function _batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert ERC1155__LengthMismatch();

        for (uint256 i; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        address sender = _msgSender();
        emit TransferBatch(sender, address(0), to, ids, amounts);

        if (
            (to == address(0) || to.code.length != 0) &&
            ERC1155TokenReceiver(to).onERC1155BatchReceived(
                sender,
                address(0),
                ids,
                amounts,
                data
            ) !=
            ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert ERC1155__UnsafeRecipient();
    }

    function _batchBurn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert ERC1155__LengthMismatch();

        for (uint256 i; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(_msgSender(), from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(_msgSender(), from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}
