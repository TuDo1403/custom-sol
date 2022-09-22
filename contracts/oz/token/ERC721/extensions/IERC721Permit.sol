// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

import "../IERC721.sol";

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    error ERC721Permit__Expired();
    error ERC721Permit__SelfApproving();

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // / @notice Approve of a specific token ID for spending by spender via signature
    // / @param spender The account that is being approved
    // / @param tokenId The ID of the token that is being approved for spending
    // / @param deadline The deadline timestamp by which the call must be mined for the approve to work
    // / @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    // / @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    // / @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        uint256 tokenId_,
        uint256 deadline_,
        address spender_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function nonces(uint256 tokenId_) external view returns (uint256);
}
