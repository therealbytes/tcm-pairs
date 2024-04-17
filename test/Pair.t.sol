// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {Test, console2} from "forge-std/Test.sol";

import {Pair, TokenId} from "../src/Pair.sol";

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
        pair.deposit(address(tokenA), amount);
        assertTrue(PairTestLib.assertDeposit(pair, tokenA, amount));
    }

    function testFailDepositInvalidToken() public {
        uint256 amount = 100;
        ERC20Mock badToken = new ERC20Mock();
        PairTestLib.mintAndApprove(badToken, address(pair), amount);
        pair.deposit(address(badToken), amount);
    }

    function testFailDepositTransferFailed() public {
        uint256 amount = 100;
        pair.deposit(address(tokenA), amount);
    }

    function testDepositLite() public {
        uint256 amount = 100;
        PairTestLib.mintAndApprove(tokenA, address(pair), amount);
        pair.depositLite(TokenId.A, amount);
        assertTrue(PairTestLib.assertDeposit(pair, tokenA, amount));
    }

    function testFailDepositLiteTransferFailed() public {
        uint256 amount = 100;
        pair.depositLite(TokenId.A, amount);
    }

    function testSwapAforB() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
        pair.swap(address(tokenA), address(tokenB), amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenA, tokenB, amount));
    }

    function testSwapBforA() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenB, tokenA, amount);
        pair.swap(address(tokenB), address(tokenA), amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenB, tokenA, amount));
    }

    function testFailSwapInvalidToken() public {
        pair.swap(address(0), address(1), 1);
    }

    function testFailSwapInvalidTokenPair() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenA, tokenA, amount);
        pair.swap(address(tokenA), address(tokenA), amount);
    }

    function testFailSwapInputTransferFailed() public {
        uint256 amount = 100;
        tokenA.mint(address(this), amount);
        pair.swap(address(tokenA), address(tokenB), amount);
    }

    function testFailSwapOutputTransferFailed() public {
        uint256 amount = 100;
        PairTestLib.mintAndApprove(tokenA, address(pair), amount);
        pair.swap(address(tokenA), address(tokenB), amount);
    }

    function testSwapLiteAforB() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
        pair.swapLite(TokenId.A, amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenA, tokenB, amount));
    }

    function testSwapLiteBforA() public {
        uint256 amount = 100;
        PairTestLib.prepareSwap(pair, tokenB, tokenA, amount);
        pair.swapLite(TokenId.B, amount);
        assertTrue(PairTestLib.assertSwap(pair, tokenB, tokenA, amount));
    }

    function testFailSwapLiteInputTransferFailed() public {
        uint256 amount = 100;
        tokenB.mint(address(pair), amount);
        pair.swapLite(TokenId.A, amount);
    }

    function testFailSwapLiteOutputTransferFailed() public {
        uint256 amount = 100;
        PairTestLib.mintAndApprove(tokenA, address(pair), amount);
        pair.swapLite(TokenId.A, amount);
    }
}
