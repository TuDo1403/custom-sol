// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";

import {Transferable} from "internal/Transferable.sol";

import {WNT} from "presets/token/WNT.sol";

contract WETHTest is DSTestPlus, Transferable {
    WNT wnt;

    function setUp() public {
        wnt = new WNT("WrappedEther", "WNT");
    }

    function testFallbackDeposit() public {
        assertEq(wnt.balanceOf(address(this)), 0);
        assertEq(wnt.totalSupply(), 0);

        _safeNativeTransfer(address(wnt), 1 ether, "");

        assertEq(wnt.balanceOf(address(this)), 1 ether);
        assertEq(wnt.totalSupply(), 1 ether);
    }

    function testDeposit() public {
        assertEq(wnt.balanceOf(address(this)), 0);
        assertEq(wnt.totalSupply(), 0);

        wnt.deposit{value: 1 ether}();

        assertEq(wnt.balanceOf(address(this)), 1 ether);
        assertEq(wnt.totalSupply(), 1 ether);
    }

    function testWithdraw() public {
        uint256 startingBalance = address(this).balance;

        wnt.deposit{value: 1 ether}();

        wnt.withdraw(1 ether);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, startingBalance);
        assertEq(wnt.balanceOf(address(this)), 0);
        assertEq(wnt.totalSupply(), 0);
    }

    function testPartialWithdraw() public {
        wnt.deposit{value: 1 ether}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        wnt.withdraw(0.5 ether);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + 0.5 ether);
        assertEq(wnt.balanceOf(address(this)), 0.5 ether);
        assertEq(wnt.totalSupply(), 0.5 ether);
    }

    function testFallbackDeposit(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);

        assertEq(wnt.balanceOf(address(this)), 0);
        assertEq(wnt.totalSupply(), 0);

        _safeNativeTransfer(address(wnt), amount, "");

        assertEq(wnt.balanceOf(address(this)), amount);
        assertEq(wnt.totalSupply(), amount);
    }

    function testDeposit(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);

        assertEq(wnt.balanceOf(address(this)), 0);
        assertEq(wnt.totalSupply(), 0);

        wnt.deposit{value: amount}();

        assertEq(wnt.balanceOf(address(this)), amount);
        assertEq(wnt.totalSupply(), amount);
    }

    function testWithdraw(
        uint256 depositAmount,
        uint256 withdrawAmount
    ) public {
        depositAmount = bound(depositAmount, 0, address(this).balance);
        withdrawAmount = bound(withdrawAmount, 0, depositAmount);

        wnt.deposit{value: depositAmount}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        wnt.withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + withdrawAmount);
        assertEq(wnt.balanceOf(address(this)), depositAmount - withdrawAmount);
        assertEq(wnt.totalSupply(), depositAmount - withdrawAmount);
    }

    receive() external payable {}
}

contract WETHInvariants is DSTestPlus, DSInvariantTest {
    WETHTester wethTester;
    WNT wnt;

    function setUp() public {
        wnt = new WNT("WrappedEther", "WETH");
        wethTester = new WETHTester{value: address(this).balance}(wnt);

        addTargetContract(address(wethTester));
    }

    function invariantTotalSupplyEqualsBalance() public {
        assertEq(address(wnt).balance, wnt.totalSupply());
    }
}

contract WETHTester is Transferable {
    WNT wnt;

    constructor(WNT _weth) payable {
        wnt = _weth;
    }

    function deposit(uint256 amount) public {
        wnt.deposit{value: amount}();
    }

    function fallbackDeposit(uint256 amount) public {
        _safeNativeTransfer(address(wnt), amount, "");
    }

    function withdraw(uint256 amount) public {
        wnt.withdraw(amount);
    }

    receive() external payable {}
}
