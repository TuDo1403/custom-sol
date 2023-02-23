// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {AccessControlEnumerable} from "oz/access/AccessControlEnumerable.sol";

import {ERC20, ERC20Permit} from "oz/token/ERC20/extensions/ERC20Permit.sol";

import {ERC20Burnable} from "oz/token/ERC20/extensions/ERC20Burnable.sol";

import {
    Pausable,
    ERC20Pausable
} from "oz/token/ERC20/extensions/ERC20Pausable.sol";

import {Taxable, FixedPointMathLib} from "internal/Taxable.sol";
import {Transferable} from "internal/Transferable.sol";
import {ProxyChecker} from "internal/ProxyChecker.sol";
import {Blacklistable} from "internal/Blacklistable.sol";

import {IWNT} from "presets/token/interfaces/IWNT.sol";

import {
    IUniswapV2Pair
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface IBountyKindsERC20 {
    error BountyKindsERC20__Blacklisted();
    error BountyKindsERC20__InvalidArguments();

    event Refunded(address indexed operator, uint256 indexed refund);

    event Executed(
        address indexed operator,
        address indexed target,
        uint256 indexed value_,
        bytes callData,
        bytes returnData
    );

    event PoolSet(
        address indexed operator,
        IUniswapV2Pair indexed poolOld,
        IUniswapV2Pair indexed poolNew
    );

    function setPool(IUniswapV2Pair pool_) external;

    function mint(address to_, uint256 amount_) external;

    function execute(
        address target_,
        uint256 value_,
        bytes calldata calldata_
    ) external;
}

import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {ErrorHandler} from "libraries/ErrorHandler.sol";

contract BountyKindsERC20Mock is
    Taxable,
    ERC20Permit,
    Transferable,
    ProxyChecker,
    Blacklistable,
    ERC20Burnable,
    ERC20Pausable,
    IBountyKindsERC20,
    AccessControlEnumerable
{
    using ErrorHandler for bool;
    using FixedPointMathLib for uint256;

    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    bytes32 public constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;

    IWNT public immutable wnt;
    AggregatorV3Interface public immutable priceFeed;

    IUniswapV2Pair public pool;

    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        uint256 initialSupply_,
        IWNT wnt_,
        IUniswapV2Pair pool_,
        AggregatorV3Interface priceFeed_
    ) payable Pausable() Taxable(admin_) ERC20Permit(name_, symbol_) {
        wnt = wnt_;
        priceFeed = priceFeed_;

        _setPool(pool_);

        _grantRole(PAUSER_ROLE, admin_);
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        //_mint(admin_, initialSupply_);
    }

    function setPool(
        IUniswapV2Pair pool_
    ) external whenPaused onlyRole(OPERATOR_ROLE) {
        _setPool(pool_);
    }

    function setUserStatus(
        address account_,
        bool status_
    ) external onlyRole(OPERATOR_ROLE) {
        _setUserStatus(account_, status_);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function toggleTax() external whenPaused onlyRole(PAUSER_ROLE) {
        _toggleTax();
    }

    function setTaxBeneficiary(
        address beneficiary_
    ) external onlyRole(OPERATOR_ROLE) {
        _setTaxBeneficiary(beneficiary_);
    }

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }

    //  @dev minimal function to recover lost funds
    function execute(
        address target_,
        uint256 value_,
        bytes calldata calldata_
    ) external whenPaused onlyRole(OPERATOR_ROLE) {
        (bool success, bytes memory returnOrRevertData) = target_.call{
            value: value_
        }(calldata_);
        success.handleRevertIfNotSuccess(returnOrRevertData);

        emit Executed(
            _msgSender(),
            target_,
            value_,
            calldata_,
            returnOrRevertData
        );
    }

    function tax(
        address pool_,
        uint256 amount_
    ) public view override returns (uint256) {
        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(pool_).getReserves();

        // amount token => amount native
        uint256 amtNative = amount_.mulDivUp(res0, res1);
        AggregatorV3Interface _priceFeed = priceFeed;
        (, int256 usd, , , ) = _priceFeed.latestRoundData();
        // amount native => amount usd
        uint256 amtUSD = amtNative.mulDivUp(
            uint256(usd),
            10 ** _priceFeed.decimals()
        );

        // usd tax amount
        uint256 usdTax = amtUSD.mulDivUp(
            taxFraction(address(0)),
            percentageFraction()
        );
        // native tax amount
        return usdTax.mulDivUp(1 ether, uint256(usd));
    }

    function taxEnabledDuration() public pure override returns (uint256) {
        return 20 minutes;
    }

    function taxFraction(address) public pure override returns (uint256) {
        return 2500;
    }

    function percentageFraction() public pure override returns (uint256) {
        return 10_000;
    }

    function _setPool(IUniswapV2Pair pool_) internal {
        // if (address(pool_) == address(0) || !_isProxy(address(pool_)))
        //     revert BountyKindsERC20__InvalidArguments();

        emit PoolSet(_msgSender(), pool, pool_);
        pool = pool_;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from_, to_, amount_);

        if (
            isBlacklisted(to_) ||
            isBlacklisted(from_) ||
            isBlacklisted(_msgSender())
        ) revert BountyKindsERC20__Blacklisted();

        if (isTaxEnabled()) {
            uint256 _tax = tax(address(pool), amount_);
            IWNT _wnt = wnt;

            if (msg.value != 0) {
                //  @dev will throw underflow error if msg.value < _tax
                uint256 refund = msg.value - _tax;
                _wnt.deposit{value: _tax}();

                address spender = _msgSender();
                if (refund != 0) {
                    _safeNativeTransfer(spender, refund, "");
                    emit Refunded(spender, refund);
                }
            }

            _safeERC20TransferFrom(_wnt, address(this), taxBeneficiary, _tax);
        }
    }
}
