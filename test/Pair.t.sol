// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

import {Test, console} from "forge-std/Test.sol";
import {Pair, TokenId} from "../src/Pair.sol";

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
        tokenA.mint(address(this), amount);
        tokenA.approve(address(pair), amount);
        pair.deposit(address(tokenA), amount);
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(address(pair)), amount);
    }

    function testFailDepositInvalidToken() public {
        uint256 amount = 100;
        ERC20Mock badToken = new ERC20Mock();
        badToken.mint(address(this), amount);
        badToken.approve(address(pair), amount);
        pair.deposit(address(badToken), amount);
    }

    function testFailDepositTransferFailed() public {
        uint256 amount = 100;
        pair.deposit(address(tokenA), amount);
    }

    function testDepositLite() public {
        uint256 amount = 100;
        tokenA.mint(address(this), amount);
        tokenA.approve(address(pair), amount);
        pair.depositLite(TokenId.A, amount);
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(address(pair)), amount);
    }

    function testFailDepositLiteTransferFailed() public {
        uint256 amount = 100;
        pair.depositLite(TokenId.A, amount);
    }

    function testSwap() public {
        uint256 amount = 100;
        // Mint A tokens for the sender.
        tokenA.mint(address(this), amount);
        // Approve pair contract to spend A tokens.
        tokenA.approve(address(pair), amount);

        // Mint B tokens for pair contract.
        tokenB.mint(address(pair), amount);

        pair.swap(address(tokenA), address(tokenB), amount);

        // Assert sender balances
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenB.balanceOf(address(this)), amount);
        // Assert contract balances
        assertEq(tokenA.balanceOf(address(pair)), amount);
        assertEq(tokenB.balanceOf(address(pair)), 0);
    }

    function testFailSwapInvalidToken() public {
        pair.swap(address(0), address(1), 1);
    }

    function testFailSwapInvalidTokenPair() public {
        pair.swap(address(tokenA), address(tokenA), 1);
    }

    function testFailSwapInputTransferFailed() public {
        uint256 amount = 100;
        tokenB.mint(address(pair), amount);
        pair.swap(address(tokenA), address(tokenB), amount);
    }

    function testFailSwapOutputTransferFailed() public {
        uint256 amount = 100;
        tokenA.mint(address(this), amount);
        tokenA.approve(address(pair), amount);
        pair.swap(address(tokenA), address(tokenB), amount);
    }

    function testSwapLiteAtoB() public {
        uint256 amount = 100;
        // Mint A tokens for the sender.
        tokenA.mint(address(this), amount);
        // Approve pair contract to spend A tokens.
        tokenA.approve(address(pair), amount);

        // Mint B tokens for pair contract.
        tokenB.mint(address(pair), amount);

        pair.swapLite(TokenId.A, amount);

        // Assert sender balances
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenB.balanceOf(address(this)), amount);
        // Assert contract balances
        assertEq(tokenA.balanceOf(address(pair)), amount);
        assertEq(tokenB.balanceOf(address(pair)), 0);
    }

    function testSwapLiteBtoA() public {
        uint256 amount = 100;
        // Mint A tokens for the sender.
        tokenB.mint(address(this), amount);
        // Approve pair contract to spend A tokens.
        tokenB.approve(address(pair), amount);

        // Mint B tokens for pair contract.
        tokenA.mint(address(pair), amount);

        pair.swapLite(TokenId.B, amount);

        // Assert sender balances
        assertEq(tokenB.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(address(this)), amount);
        // Assert contract balances
        assertEq(tokenB.balanceOf(address(pair)), amount);
        assertEq(tokenA.balanceOf(address(pair)), 0);
    }

    function testFailSwapLiteInputTransferFailed() public {
        uint256 amount = 100;
        tokenB.mint(address(pair), amount);
        pair.swapLite(TokenId.A, amount);
    }

    function testFailSwapLiteOutputTransferFailed() public {
        uint256 amount = 100;
        tokenA.mint(address(this), amount);
        tokenA.approve(address(pair), amount);
        pair.swapLite(TokenId.A, amount);
    }
}
