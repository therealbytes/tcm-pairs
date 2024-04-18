// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

import {Test, console2} from "forge-std/Test.sol";

import {TokenId} from "../src/Pair.sol";
import {RateLimitedPair, RateLimitExceeded} from "../src/RateLimitedPair.sol";

import {PairTestLib} from "./Pair.t.sol";

contract RateLimitedPairTest is Test {
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;

    function setUp() public {
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
    }

    function testSwap() public {
        uint256 amount = 100;
        uint256 iters = 3;

        uint256 rateLimit = amount * iters;
        RateLimitedPair pair = new RateLimitedPair(
            address(tokenA),
            address(tokenB),
            rateLimit
        );

        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < iters; j++) {
                PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
                pair.swap(address(tokenA), address(tokenB), amount);
                assertEq(tokenA.balanceOf(address(this)), 0);
                assertEq(tokenB.balanceOf(address(pair)), 0);
                vm.warp(block.timestamp + 1 seconds);
            }
            vm.warp(block.timestamp + 24 hours + 1 seconds);
        }
    }

    function testSwap24HoursIn() public {
        vm.warp(24 hours);
        testSwap();
    }

    function testRevertSwapRateLimitExceeded() public {
        uint256 amount = 100;
        uint256 iters = 3;

        uint256 rateLimit = amount * iters;
        RateLimitedPair pair = new RateLimitedPair(
            address(tokenA),
            address(tokenB),
            rateLimit
        );

        for (uint256 j = 0; j < iters; j++) {
            PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
            pair.swap(address(tokenA), address(tokenB), amount);
            assertEq(tokenA.balanceOf(address(this)), 0);
            assertEq(tokenB.balanceOf(address(pair)), 0);
            vm.warp(block.timestamp + 1 seconds);
        }

        PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
        vm.expectRevert(RateLimitExceeded.selector);
        pair.swap(address(tokenA), address(tokenB), amount);
    }

    function testRevertSwapRateLimitExceeded24HoursIn() public {
        vm.warp(24 hours);
        testRevertSwapRateLimitExceeded();
    }
}
