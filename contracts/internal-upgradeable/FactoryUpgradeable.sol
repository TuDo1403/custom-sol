// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "../oz-upgradeable/proxy/utils/Initializable.sol";
import "../oz-upgradeable/utils/Create2Upgradeable.sol";
import "../oz-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import "./interfaces/IFactoryUpgradeable.sol";

import "../libraries/CREATE3.sol";
import "../libraries/Bytes32Address.sol";

abstract contract FactoryUpgradeable is IFactoryUpgradeable, Initializable {
    using Bytes32Address for address;
    using Bytes32Address for bytes32;
    using ClonesUpgradeable for address;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    BitMapsUpgradeable.BitMap private __deployed;
    mapping(bytes4 => bytes32) private __implements;

    function __Factory_init() internal onlyInitializing {}

    function __Factory_init_unchained() internal onlyInitializing {}

    function implement(bytes4 interfaceId_) public view returns (address) {
        return __implements[interfaceId_].fromFirst20Bytes();
    }

    function deployed(address addr_) public view returns (bool) {
        return __deployed.get(addr_.fillFirst96Bits());
    }

    function cloneOf(bytes4 interfaceId_, bytes32 salt_)
        external
        view
        returns (address clone, bool isCloned)
    {
        clone = implement(interfaceId_).predictDeterministicAddress(
            salt_,
            address(this)
        );
        isCloned = deployed(clone);
    }

    function instanceOf(bytes32 bytecodeHash_, bytes32 salt_)
        external
        view
        returns (address instance, bool isDeployed)
    {
        instance = Create2Upgradeable.computeAddress(salt_, bytecodeHash_);
        isDeployed = deployed(instance);
    }

    function instanceOf(bytes32 salt_)
        external
        view
        returns (address instance, bool isDeployed)
    {
        instance = CREATE3.getDeployed(salt_);
        isDeployed = deployed(instance);
    }

    function _setImplement(bytes4 interfaceId_, address implement_) internal {
        __implements[interfaceId_] = implement_.fillLast12Bytes();
        __deployed.set(implement_.fillLast96Bits());
    }

    function _cheapClone(
        bytes32 salt_,
        bytes4 interfaceId_,
        bytes4 selector_,
        bytes memory args_
    ) internal returns (address clone) {
        address impl = implement(interfaceId_);
        if (impl == address(0)) revert Factory__NonExistImplement();
        clone = impl.cloneDeterministic(salt_);
        (bool ok, ) = clone.call(abi.encodePacked(selector_, args_));
        if (!ok) revert Factory__CloneFailed();

        emit Cloned(impl, salt_, clone);
    }

    uint256[48] private __gap;
}
