// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

import {Test, console} from "forge-std/Test.sol";
import {Pair} from "../src/Pair.sol";

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
        pair.deposit(amount, address(tokenA));
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(address(pair)), amount);
    }

    function testFailDepositInvalidToken() public {
        uint256 amount = 100;
        ERC20Mock badToken = new ERC20Mock();
        badToken.mint(address(this), amount);
        badToken.approve(address(pair), amount);
        pair.deposit(amount, address(badToken));
    }

    function testFailDepositTransferFailed() public {
        uint256 amount = 100;
        pair.deposit(amount, address(tokenA));
    }

    function testExchange() public {
        uint256 amount = 100;
        // Mint A tokens for the sender.
        tokenA.mint(address(this), amount);
        // Approve pair contract to spend A tokens.
        tokenA.approve(address(pair), amount);

        // Mint B tokens for pair contract.
        tokenB.mint(address(pair), amount);

        pair.exchange(amount, address(tokenA), address(tokenB));

        // Assert sender balances
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenB.balanceOf(address(this)), amount);
        // Assert contract balances
        assertEq(tokenA.balanceOf(address(pair)), amount);
        assertEq(tokenB.balanceOf(address(pair)), 0);
    }

    function testFailExchangeInvalidToken() public {
        pair.exchange(1, address(0), address(1));
    }

    function testFailExchangeInvalidTokenPair() public {
        pair.exchange(1, address(tokenA), address(tokenA));
    }

    function testFailExchangeInputTransferFailed() public {
        uint256 amount = 100;
        tokenB.mint(address(pair), amount);
        pair.exchange(amount, address(tokenA), address(tokenB));
    }

    function testFailExchangeOutputTransferFailed() public {
        uint256 amount = 100;
        tokenA.mint(address(this), amount);
        tokenA.approve(address(pair), amount);
        pair.exchange(amount, address(tokenA), address(tokenB));
    }

    function testExchangeLiteAtoB() public {
        uint256 amount = 100;
        // Mint A tokens for the sender.
        tokenA.mint(address(this), amount);
        // Approve pair contract to spend A tokens.
        tokenA.approve(address(pair), amount);

        // Mint B tokens for pair contract.
        tokenB.mint(address(pair), amount);

        pair.exchangeLite(amount, pair.A_TO_B());

        // Assert sender balances
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenB.balanceOf(address(this)), amount);
        // Assert contract balances
        assertEq(tokenA.balanceOf(address(pair)), amount);
        assertEq(tokenB.balanceOf(address(pair)), 0);
    }

    function testExchangeLiteBtoA() public {
        uint256 amount = 100;
        // Mint A tokens for the sender.
        tokenB.mint(address(this), amount);
        // Approve pair contract to spend A tokens.
        tokenB.approve(address(pair), amount);

        // Mint B tokens for pair contract.
        tokenA.mint(address(pair), amount);

        pair.exchangeLite(amount, !pair.A_TO_B());

        // Assert sender balances
        assertEq(tokenB.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(address(this)), amount);
        // Assert contract balances
        assertEq(tokenB.balanceOf(address(pair)), amount);
        assertEq(tokenA.balanceOf(address(pair)), 0);
    }

    function testFailExchangeLiteInputTransferFailed() public {
        uint256 amount = 100;
        tokenB.mint(address(pair), amount);
        pair.exchangeLite(amount, pair.A_TO_B());
    }

    function testFailExchangeLiteOutputTransferFailed() public {
        uint256 amount = 100;
        tokenA.mint(address(this), amount);
        tokenA.approve(address(pair), amount);
        pair.exchangeLite(amount, pair.A_TO_B());
    }
}
