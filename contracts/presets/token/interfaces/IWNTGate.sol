pragma solidity ^0.8.17;

import {IWNT} from "./IWNT.sol";

interface IWNTGate {
    error WNTGate__InvalidAddress();

    event Withdrawal(address indexed receiver, uint256 wad);
    event Received(address indexed sender, uint256 indexed amount);

    /// @dev Transfer assets to a receiver.
    /// @param receiver This address will receive a transfer.
    /// @param wad Amount in wei
    function withdraw(address receiver, uint256 wad) external;

    function wnt() external view returns (IWNT);
}
