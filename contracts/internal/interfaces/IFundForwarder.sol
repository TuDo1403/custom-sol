// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../oz/token/ERC20/IERC20.sol";

import {
    IERC721,
    IERC721Enumerable
} from "../../oz/token/ERC721/extensions/IERC721Enumerable.sol";

interface IFundForwarder {
    error FundForwarder__ForwardFailed();
    error FundForwarder__InvalidArgument();

    /**
     * @dev Emits when the vault address is updated
     * @param from Old vault address
     * @param to New vault address
     */
    event VaultUpdated(address indexed from, address indexed to);

    /**
     *@dev Emits when a single ERC721 token is recovered
     *@param operator Address of the contract calling this function
     *@param token Address of the token contract
     *@param value Token ID of the recovered token
     */
    event Recovered(
        address indexed operator,
        address indexed token,
        uint256 indexed value
    );

    /**
     *@dev Emits when multiple ERC721 tokens are recovered
     *@param operator Address of the contract calling this function
     *@param token Address of the token contract
     *@param values Token IDs of the recovered tokens
     */
    event RecoveredMulti(
        address indexed operator,
        address indexed token,
        uint256[] values
    );

    /**
     * @dev Emits when funds are forwarded
     * @param from Address of the sender
     * @param amount Amount of funds forwarded
     */
    event Forwarded(address indexed from, uint256 indexed amount);

    function changeVault(address vault_) external;

    function vault() external view returns (address);

    /**
     * @dev Recovers ERC20 token to the vault address
     * @param token_ ERC20 token contract
     * @param amount_ Amount of tokens to recover
     */
    function recoverERC20(IERC20 token_, uint256 amount_) external;

    /**
     *@dev Recovers ERC721 token to the vault address
     *@param token_ ERC721 token contract
     *@param tokenId_ ID of the token to recover
     */
    function recoverNFT(IERC721 token_, uint256 tokenId_) external;

    /**
     *@dev Recovers all ERC721 tokens of the contract to the vault address
     *@param token_ ERC721Enumerable token contract
     */
    function recoverNFTs(IERC721Enumerable token_) external;

    /**
     * @dev Recovers native currency to the vault address
     */
    function recoverNative() external;
}
