// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "../internal/ProxyChecker.sol";
// import "../internal/FundForwarder.sol";

// import "./interfaces/IMultiSigWallet.sol";

// import "../libraries/SSTORE2.sol";
// import "../oz/utils/structs/BitMaps.sol";

// contract MultiSigWallet is ProxyChecker, FundForwarder, IMultiSigWallet {
//     using SSTORE2 for *;
//     using Bytes32Address for *;
//     using BitMaps for BitMaps.BitMap;

//     /// @dev value is equal to keccak256("MultiSigWallet_v1)
//     bytes32 public constant VERSION =
//         0xc84bb06d017413e5abafccf36d331267c4ee0236baf4b79e92594fe3d4ef3c24;

//     uint256 public transactionCounter;
//     uint256 public immutable numConfirmationsRequired;

//     mapping(uint256 => Transaction) public transactions;

//     bytes32 private __ownersPointer;
//     BitMaps.BitMap private __isOwner;
//     mapping(address => BitMaps.BitMap) private __isConfirmed;

//     // mapping from tx index => owner => bool
//     //mapping(uint256 => mapping(address => bool)) public isConfirmed;

//     // Transaction[] public transactions;

//     modifier onlyOwner() {
//         __checkOwner(_msgSender());
//         _;
//     }

//     modifier txExists(uint256 _txIndex) {
//         require(_txIndex < transactions.length, "tx does not exist");
//         _;
//     }

//     modifier notExecuted(uint256 _txIndex) {
//         require(!transactions[_txIndex].executed, "tx already executed");
//         _;
//     }

//     modifier notConfirmed(uint256 _txIndex) {
//         require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
//         _;
//     }

//     constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
//         require(_owners.length > 0, "owners required");
//         require(
//             _numConfirmationsRequired > 0 &&
//                 _numConfirmationsRequired <= _owners.length,
//             "invalid number of required confirmations"
//         );

//         for (uint256 i = 0; i < _owners.length; i++) {
//             address owner = _owners[i];

//             require(owner != address(0), "invalid owner");
//             require(!isOwner[owner], "owner not unique");

//             isOwner[owner] = true;
//             owners.push(owner);
//         }

//         numConfirmationsRequired = _numConfirmationsRequired;
//     }

//     receive() external payable {
//         emit Deposited(msg.sender, msg.value, address(this).balance);
//     }

//     function submitTransaction(
//         address _to,
//         uint256 _value,
//         bytes memory _data
//     ) public onlyOwner {
//         uint256 txIndex = transactions.length;

//         transactions.push(
//             Transaction({
//                 to: _to,
//                 value: _value,
//                 data: _data,
//                 executed: false,
//                 numConfirmations: 0
//             })
//         );

//         emit TransactionSubmited(msg.sender, txIndex, _to, _value, _data);
//     }

//     function confirmTransaction(
//         uint256 _txIndex
//     )
//         public
//         onlyOwner
//         txExists(_txIndex)
//         notExecuted(_txIndex)
//         notConfirmed(_txIndex)
//     {
//         Transaction storage transaction = transactions[_txIndex];
//         transaction.numConfirmations += 1;
//         isConfirmed[_txIndex][msg.sender] = true;

//         emit ConfirmTransaction(msg.sender, _txIndex);
//     }

//     function executeTransaction(
//         uint256 _txIndex
//     ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
//         Transaction storage transaction = transactions[_txIndex];

//         require(
//             transaction.numConfirmations >= numConfirmationsRequired,
//             "cannot execute tx"
//         );

//         transaction.executed = true;

//         (bool success, ) = transaction.to.call{value: transaction.value}(
//             transaction.data
//         );
//         require(success, "tx failed");

//         emit ExecuteTransaction(msg.sender, _txIndex);
//     }

//     function revokeConfirmation(
//         uint256 _txIndex
//     ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
//         Transaction storage transaction = transactions[_txIndex];

//         require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

//         transaction.numConfirmations -= 1;
//         isConfirmed[_txIndex][msg.sender] = false;

//         emit RevokeConfirmation(msg.sender, _txIndex);
//     }

//     function getOwners() public view returns (address[] memory) {
//         return owners;
//     }

//     function getTransactionCount() public view returns (uint256) {
//         return transactions.length;
//     }

//     function getTransaction(
//         uint256 _txIndex
//     )
//         public
//         view
//         returns (
//             address to,
//             uint256 value,
//             bytes memory data,
//             bool executed,
//             uint256 numConfirmations
//         )
//     {
//         Transaction storage transaction = transactions[_txIndex];

//         return (
//             transaction.to,
//             transaction.value,
//             transaction.data,
//             transaction.executed,
//             transaction.numConfirmations
//         );
//     }

//     function __checkOwner(address account_) private view {
//         if (__isOwner.get(account_.fillLast96Bits()))
//             revert MultiSigWallet__Unauthorized();
//     }
// }
