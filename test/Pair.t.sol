// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {Test, console2} from "forge-std/Test.sol";

import {Pair, TokenId, InvalidToken, InvalidTokenPair, TransferFailed} from "../src/Pair.sol";

library PairTestLib {
    function mintAndApprove(
        ERC20Mock token,
        address spender,
        uint256 amount
    ) public {
        token.mint(address(this), amount);
        token.approve(spender, amount);
    }

    function prepareSwap(
        Pair pair,
        ERC20Mock tokenA,
        ERC20Mock tokenB,
        uint256 amount
    ) public {
        mintAndApprove(tokenA, address(pair), amount);
        tokenB.mint(address(pair), amount);
    }

    function assertDeposit(
        Pair pair,
        ERC20Mock token,
        uint256 amount
    ) public view returns (bool) {
        return
            token.balanceOf(address(this)) == 0 &&
            token.balanceOf(address(pair)) == amount;
    }

    function assertSwap(
        Pair pair,
        ERC20Mock tokenA,
        ERC20Mock tokenB,
        uint256 amount
    ) public view returns (bool) {
        return
            tokenA.balanceOf(address(this)) == 0 &&
            tokenB.balanceOf(address(this)) == amount &&
            tokenA.balanceOf(address(pair)) == amount &&
            tokenB.balanceOf(address(pair)) == 0;
    }
}

contract PairTest is Test {
    event Deposited(address indexed token, uint256 amount);

    event Swapped(
        address indexed fromToken,
        address indexed toToken,
        uint256 amount
    );

    ERC20Mock public tokenA;
    ERC20Mock public tokenB;

    Pair public pair;

    function setUp() public {
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        pair = new Pair(address(tokenA), address(tokenB));
    }

    function testDeposit() public {
        uint256 amount = 100;
        PairTestLib.mintAndApprove(tokenA, address(pair), amount);
        vm.expectEmit(true, false, false, true);
        emit Deposited(address(tokenA), amount);
        pair.deposit(address(tokenA), amount);
        assertTrue(PairTestLib.assertDeposit(pair, tokenA, amount));
    }

    function testRevertDepositInvalidToken() public {
        uint256 amount = 100;
        ERC20Mock badToken = new ERC20Mock();
        PairTestLib.mintAndApprove(badToken, address(pair), amount);
        vm.expectRevert(InvalidToken.selector);
        pair.deposit(address(badToken), amount);
    }

    function testRevertDepositTransferFailed() public {
        uint256 amount = 100;
        vm.expectRevert();
        pair.deposit(address(tokenA), amount);
    }

    function testDepositLite() public {
        uint256 amount = 100;
        PairTestLib.mintAndApprove(tokenA, address(pair), amount);
        vm.expectEmit(true, false, false, true);
        emit Deposited(address(tokenA), amount);
        pair.depositLite(TokenId.A, amount);
        assertTrue(PairTestLib.assertDeposit(pair, tokenA, amount));
    }

    function testRevertDepositLiteTransferFailed() public {
        uint256 amount = 100;
        vm.expectRevert();
        pair.depositLite(TokenId.A, amount);
    }

    function testSwapAforB() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
        vm.expectEmit(true, true, false, true);
        emit Swapped(address(tokenA), address(tokenB), amount);
        pair.swap(address(tokenA), address(tokenB), amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenA, tokenB, amount));
    }

    function testSwapBforA() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenB, tokenA, amount);
        vm.expectEmit(true, true, false, true);
        emit Swapped(address(tokenB), address(tokenA), amount);
        pair.swap(address(tokenB), address(tokenA), amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenB, tokenA, amount));
    }

    function testRevertSwapInvalidToken() public {
        vm.expectRevert(InvalidToken.selector);
        pair.swap(address(0), address(1), 1);
    }

    function testRevertSwapInvalidTokenPair() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenA, tokenA, amount);
        vm.expectRevert(InvalidTokenPair.selector);
        pair.swap(address(tokenA), address(tokenA), amount);
    }

    function testRevertSwapInputTransferFailed() public {
        uint256 amount = 100;
        tokenA.mint(address(this), amount);
        vm.expectRevert();
        pair.swap(address(tokenA), address(tokenB), amount);
    }

    function testRevertSwapOutputTransferFailed() public {
        uint256 amount = 100;
        PairTestLib.mintAndApprove(tokenA, address(pair), amount);
        vm.expectRevert();
        pair.swap(address(tokenA), address(tokenB), amount);
    }

    function testSwapLiteAforB() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
        vm.expectEmit(true, true, false, true);
        emit Swapped(address(tokenA), address(tokenB), amount);
        pair.swapLite(TokenId.A, amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenA, tokenB, amount));
    }

    function testSwapLiteBforA() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenB, tokenA, amount);
        vm.expectEmit(true, true, false, true);
        emit Swapped(address(tokenB), address(tokenA), amount);
        pair.swapLite(TokenId.B, amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenB, tokenA, amount));
    }

    function testRevertSwapLiteInputTransferFailed() public {
        uint256 amount = 100;
        tokenB.mint(address(pair), amount);
        vm.expectRevert();
        pair.swapLite(TokenId.A, amount);
    }

    function testRevertSwapLiteOutputTransferFailed() public {
        uint256 amount = 100;
        PairTestLib.mintAndApprove(tokenA, address(pair), amount);
        vm.expectRevert();
        pair.swapLite(TokenId.A, amount);
    }
}
