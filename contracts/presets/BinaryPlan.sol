// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../oz/proxy/utils/Initializable.sol";

import "./base/Manager.sol";

import "./interfaces/IBinaryPlan.sol";

/**
 * @title BinaryPlan
 * @dev Implements a binary tree-like plan to reward referrals.
 * @notice This contract only allows the factory contract to create an instance.
 * @notice The factory contract only allows the operator to call certain functions.
 */
contract BinaryPlan is Manager, IBinaryPlan, Initializable {
    /**
     * @dev The fraction of the maximum rate for each referral.
     * @notice The maximum rate for a direct referral is equal to
     *   `MAXIMUM_BONUS_PERCENTAGE / PERCENTAGE_FRACTION`.
     */
    uint256 public constant PERCENTAGE_FRACTION = 10_000;

    /**
     * @dev The maximum rate for a direct referral.
     * @notice The maximum rate for a direct referral is equal to
     *   `MAXIMUM_BONUS_PERCENTAGE / PERCENTAGE_FRACTION`.
     */
    uint256 public constant MAXIMUM_BONUS_PERCENTAGE = 3_000_000;

    /**
     * @dev The authority contract instance.
     * @notice This variable is used to cache the contract instance in order to
     *   minimize the number of contract calls.
     */
    IAuthority public immutable cachedAuthority;

    /**
     * @dev The rate of bonuses for referrals.
     */
    Bonus public bonusRate;

    /**
     * @dev The indices of the accounts in the binary heap.
     * @notice The key is the account address.
     */
    mapping(address => uint256) public indices;

    /**
     * @dev The accounts in the binary heap.
     * @notice The key is the account address.
     */
    mapping(address => Account) public accounts;

    /**
     * @dev The accounts in the binary heap.
     * @notice The key is the index of the account in the binary heap.
     */
    mapping(uint256 => address) public binaryHeap;

    /**
     * @dev Constructor that sets the authority contract instance.
     * @param authority_ The authority contract instance.
     * @notice This function only allows the factory contract to create an
     *   instance.
     */
    constructor(IAuthority authority_) payable Manager(authority_, 0) {
        cachedAuthority = authority_;
    }

    /**
     * @dev Destroys the contract and sends the balance to the caller.
     * @notice This function only allows the operator to call.
     */
    function kill() external onlyRole(Roles.OPERATOR_ROLE) {
        selfdestruct(payable(_msgSender()));
    }

    /**
     * @dev Initializes the BinaryPlan contract.
     * @param root_ The root of the binary tree, who is responsible for the referral network.
     * @notice Only callable once and by the factory role.
     */
    function initialize(address root_) external initializer {
        // Assign the root_ to the root position in the binary heap
        binaryHeap[1] = root_;
        // Assign the index of the root in the binary heap to the root's entry in the indices mapping
        indices[root_] = 1;

        // Update the contract's authority to the cached authority
        __updateAuthority(cachedAuthority);
        // Check that the caller of the function has the FACTORY_ROLE role
        _checkRole(Roles.FACTORY_ROLE, _msgSender());

        // Set the rate of bonus for branches and direct referrals
        Bonus memory bonus = bonusRate;
        bonus.branchRate = 300;
        bonus.directRate = 600;
        bonusRate = bonus;
    }

    /**
     * @dev Returns the root of the binary tree
     * @return The address of the root
     */
    function root() public view returns (address) {
        // Return the root of the binary tree, which is stored at index 1 in the binary heap
        return binaryHeap[1];
    }

    /**
     * @dev Returns an array of addresses representing the nodes in the binary tree
     * @param root_ The address of the root of the tree to retrieve
     * @return tree An array of addresses representing the nodes in the binary tree
     */
    function getTree(
        address root_
    ) external view returns (address[] memory tree) {
        Account memory account = accounts[root_];
        uint256 level = account.leftHeight >= account.rightHeight
            ? account.leftHeight
            : account.rightHeight;
        uint256 length = 1 << (level + 1);
        tree = new address[](length);
        __traversePreorder(root_, 1, tree);
    }

    /**
     * @dev Traverses the tree in preorder and assigns each node's address to the corresponding index in the given array
     * @param root_ The address of the root of the tree to traverse
     * @param idx The current index in the array to assign the current node's address to
     * @param addrs The array to assign the node addresses to
     */
    function __traversePreorder(
        address root_,
        uint256 idx,
        address[] memory addrs
    ) private view {
        if (root_ == address(0)) return;

        addrs[idx] = root_;

        __traversePreorder(
            binaryHeap[__leftChildIndexOf(root_)],
            idx << 1,
            addrs
        );
        __traversePreorder(
            binaryHeap[__rightChildIndexOf(root_)],
            (idx << 1) + 1,
            addrs
        );
    }

    /**
     * @dev Adds a referrer to the binary tree and updates their bonus rate
     * @param referrer Address of the referrer to add
     * @param referree Address of the referree to add
     * @param isLeft Flag indicating whether the referree should be added as a left or right child of the referrer
     */
    function addReferrer(
        address referrer,
        address referree,
        bool isLeft
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        require(
            referree != referrer &&
                referree != address(0) &&
                referrer != address(0),
            "BINARY_PLAN: INVALID_ARGUMENT"
        );
        require(indices[referrer] != 0, "BINARY_PLAN: NON_EXISTED_REF");
        require(indices[referree] == 0, "BINARY_PLAN: EXISTED_IN_TREE");

        uint256 position = isLeft
            ? __emptyLeftChildIndexOf(referrer)
            : __emptyRightChildIndexOf(referrer);

        binaryHeap[position] = referree;

        indices[referree] = position;
        accounts[referree].directReferrer = referrer;

        address leaf = referree;
        address root_ = __parentOf(leaf);
        uint256 leafLevel = __levelOf(position);

        uint8 heightDiff;
        Account memory rootAccount;
        while (root_ != address(0)) {
            rootAccount = accounts[root_];
            heightDiff = uint8(leafLevel - __levelOf(indices[root_]));
            if (
                rootAccount.leftHeight < heightDiff &&
                __isLeftBranch(leaf, root_)
            ) rootAccount.leftHeight = heightDiff;
            else if (rootAccount.rightHeight < heightDiff)
                rootAccount.rightHeight = heightDiff;

            accounts[root_] = rootAccount;

            leaf = root_;
            root_ = __parentOf(leaf);
        }
    }

    function isPerfect(
        uint256 rootIdx_,
        uint256 depth_,
        uint256 level_
    ) public view returns (bool) {
        unchecked {
            if (depth_ == level_) return true;

            if (binaryHeap[rootIdx_] == address(0)) return true;

            uint256 left = rootIdx_ << 1;
            uint256 right = (rootIdx_ << 1) + 1;
            address leftAddr = binaryHeap[left];
            address rightAddr = binaryHeap[right];

            if (leftAddr == address(0) && rightAddr == address(0))
                return depth_ == level_;

            if (leftAddr == address(0) || rightAddr == address(0)) return false;

            if (leftAddr != address(0) && rightAddr != address(0))
                return
                    isPerfect(left, depth_, level_ + 1) &&
                    isPerfect(right, depth_, level_ + 1);

            return false;
        }
    }

    function updateVolume(
        address account,
        uint96 volume
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        Account memory _account = accounts[account];

        accounts[_account.directReferrer].directBonus += uint96(
            (volume * bonusRate.directRate) / PERCENTAGE_FRACTION
        );

        if (_account.maxVolume < volume) _account.maxVolume = volume;

        accounts[account] = _account;

        address leaf = account;
        address root_ = __parentOf(leaf);

        while (root_ != address(0)) {
            if (__isLeftBranch(leaf, root_))
                accounts[root_].leftVolume += volume;
            else accounts[root_].rightVolume += volume;

            leaf = root_;
            root_ = __parentOf(leaf);
        }
    }

    function withdrawableAmt(
        address account_
    ) public view returns (uint256 claimable) {
        Account memory account = accounts[account_];

        uint256 branchRate = bonusRate.branchRate;

        uint256 percentageFraction = PERCENTAGE_FRACTION;
        uint256 maxReceived = (account.maxVolume * MAXIMUM_BONUS_PERCENTAGE) /
            percentageFraction;
        uint256 minHeight = account.leftHeight < account.rightHeight
            ? account.leftHeight
            : account.rightHeight;
        uint256 bonusPercentage;
        uint256 idx = indices[account_];
        for (uint256 i = 1; i <= minHeight; ) {
            unchecked {
                if (isPerfect(idx, i, 0)) bonusPercentage += branchRate;
                else break;
                ++i;
            }
        }
        uint256 bonus = account.leftVolume < account.rightVolume
            ? account.leftVolume
            : account.rightVolume;
        uint256 received = account.directBonus +
            ((bonus * bonusPercentage) / percentageFraction);

        claimable = maxReceived > received ? received : maxReceived;

        if (claimable > account.claimed) claimable -= account.claimed;
        else return 0;
    }

    function updateClaimableAmt(
        address account_,
        uint256 claimed_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        accounts[account_].claimed += uint96(claimed_);
    }

    function numBalancedLevel(
        address account_
    ) external view returns (uint256 numBalanced) {
        Account memory account = accounts[account_];
        uint256 minHeight = account.leftHeight < account.rightHeight
            ? account.leftHeight
            : account.rightHeight;
        uint256 idx = indices[account_];
        for (uint256 i = 1; i <= minHeight; ) {
            unchecked {
                if (isPerfect(idx, i, 0)) ++numBalanced;
                else break;
                ++i;
            }
        }
    }

    function isIndexLeftBranch(
        uint256 leafIdx,
        uint256 rootIdx
    ) public pure returns (bool) {
        return rootIdx >> 1 == leafIdx;
    }

    function isLeftBranch(
        address leaf_,
        address root_
    ) public view returns (bool) {
        uint256 leafIndex = indices[leaf_];
        uint256 rootIndex = indices[root_];
        return rootIndex >> 1 == leafIndex;
    }

    function __isLeftBranch(
        address leaf,
        address root_
    ) private view returns (bool) {
        uint256 leafIndex = indices[leaf];
        uint256 numPath = __levelOf(leafIndex) - __levelOf(indices[root_]) - 1; // x levels requires x - 1 steps
        return (leafIndex >> numPath) & 0x1 == 0;
    }

    function __parentOf(address account_) private view returns (address) {
        return binaryHeap[indices[account_] >> 1];
    }

    function __emptyLeftChildIndexOf(
        address account_
    ) private view returns (uint256 idx) {
        if (account_ == address(0)) return 1;
        while (account_ != address(0)) {
            idx = __leftChildIndexOf(account_);
            account_ = binaryHeap[idx];
        }
        return idx;
    }

    function __emptyRightChildIndexOf(
        address account_
    ) private view returns (uint256 idx) {
        if (account_ == address(0)) return 1;
        while (account_ != address(0)) {
            idx = __rightChildIndexOf(account_);
            account_ = binaryHeap[idx];
        }
        return idx;
    }

    function __leftChildIndexOf(
        address account_
    ) private view returns (uint256) {
        return (indices[account_] << 1);
    }

    function __rightChildIndexOf(
        address account_
    ) private view returns (uint256) {
        unchecked {
            return (indices[account_] << 1) + 1;
        }
    }

    function __levelOf(uint256 x) private pure returns (uint8 r) {
        if (x == 0) return 0;

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}
