// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";
import "../../utils/structs/BitMaps.sol";
import "./IERC721.sol";
import "./extensions/IERC721Metadata.sol";

import "../../../libraries/Bytes32Address.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Bytes32Address for address;
    using Bytes32Address for bytes32;
    using Bytes32Address for uint256;

    using BitMaps for BitMaps.BitMap;
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
    mapping(bytes32 => uint256) internal _balanceOf;

    function ownerOf(
        uint256 id
    ) public view virtual override returns (address owner) {
        if ((owner = _ownerOf[id].fromFirst20Bytes()) == address(0))
            revert ERC721__NotMinted();
    }

    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        if (owner == address(0)) revert ERC721__NonZeroAddress();

        return _balanceOf[owner.fillLast12Bytes()];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bytes32) internal _getApproved;

    mapping(bytes32 => BitMaps.BitMap) internal _isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) payable {
        if (bytes(_name).length > 32 || bytes(_symbol).length > 32)
            revert ERC721__StringTooLong();
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual override {
        address owner = _ownerOf[id].fromFirst20Bytes();
        address sender = _msgSender();
        if (
            sender != owner &&
            !_isApprovedForAll[owner.fillLast12Bytes()].get(
                sender.fillLast96Bits()
            )
        ) revert ERC721__Unauthorized();

        _getApproved[id] = spender.fillLast12Bytes();

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        address sender = _msgSender();
        _isApprovedForAll[sender.fillLast12Bytes()].setTo(
            operator.fillLast96Bits(),
            approved
        );

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
    ) external view override returns (bool) {
        return
            _isApprovedForAll[owner.fillLast12Bytes()].get(
                operator.fillLast96Bits()
            );
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            _isApprovedForAll[owner.fillLast12Bytes()].get(
                spender.fillLast96Bits()
            ) ||
            _getApproved[tokenId] == spender.fillLast12Bytes());
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
        if (from != _ownerOf[id].fromFirst20Bytes()) revert ERC721__WrongFrom();
        if (to == address(0)) revert ERC721__InvalidRecipient();
        _beforeTokenTransfer(from, to, id);

        address sender = _msgSender();
        bytes32 _from = from.fillLast12Bytes();
        if (
            sender != from &&
            !_isApprovedForAll[_from].get(sender.fillLast96Bits()) &&
            sender.fillLast12Bytes() != _getApproved[id]
        ) revert ERC721__Unauthorized();

        bytes32 _to = to.fillLast12Bytes();
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[_from]--;

            _balanceOf[_to]++;
        }

        _ownerOf[id] = _to;

        delete _getApproved[id];

        emit Transfer(from, to, id);

        _afterTokenTransfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(
                _msgSender(),
                from,
                id,
                ""
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual override {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(
                _msgSender(),
                from,
                id,
                data
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from != _ownerOf[tokenId].fromFirst20Bytes())
            revert ERC721__WrongFrom();
        if (to == address(0)) revert ERC721__InvalidRecipient();
        _beforeTokenTransfer(from, to, tokenId);

        bytes32 _to = to.fillLast12Bytes();

        unchecked {
            --_balanceOf[from.fillLast12Bytes()];
            ++_balanceOf[_to];
        }
        _ownerOf[tokenId] = _to;

        delete _getApproved[tokenId];

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
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
        if (_ownerOf[id] != 0) revert ERC721__AlreadyMinted();

        _beforeTokenTransfer(address(0), to, id);
        bytes32 _to = to.fillLast12Bytes();
        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[_to]++;
        }
        _ownerOf[id] = _to;

        emit Transfer(address(0), to, id);

        _afterTokenTransfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id].fromFirst20Bytes();

        if (owner == address(0)) revert ERC721__NotMinted();

        _beforeTokenTransfer(owner, address(0), id);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner.fillLast12Bytes()]--;
        }

        delete _ownerOf[id];
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
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(
                _msgSender(),
                address(0),
                id,
                ""
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(
                _msgSender(),
                address(0),
                id,
                data
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
