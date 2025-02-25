// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {Test, console2} from "forge-std/Test.sol";
import {TokenId} from "../src/Pair.sol";
import {VolumeLimitedPair, VolumeLimitExceeded} from "../src/VolumeLimitedPair.sol";
import {PairTestLib} from "./Pair.t.sol";

contract VolumeLimitedPairTest is Test {
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;

    function setUp() public {
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
    }

    function callSwap(
        VolumeLimitedPair pair,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount,
        bool lite
    ) public {
        if (lite) {
            TokenId fromTokenId;
            if (fromTokenAddress == address(tokenA)) {
                fromTokenId = TokenId.A;
            } else {
                fromTokenId = TokenId.B;
            }
            pair.swapLite(fromTokenId, amount);
        } else {
            pair.swap(fromTokenAddress, toTokenAddress, amount);
        }
    }

    function _testSwap(bool lite) internal {
        uint256 amount = 100;
        uint256 iters = 3;

        uint256 volumeLimit = amount * iters;
        VolumeLimitedPair pair = new VolumeLimitedPair(
            address(tokenA),
            address(tokenB),
            volumeLimit
        );

        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < iters; j++) {
                PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
                callSwap(pair, address(tokenA), address(tokenB), amount, lite);
                assertEq(tokenA.balanceOf(address(this)), 0);
                assertEq(tokenB.balanceOf(address(pair)), 0);
                vm.warp(block.timestamp + 1 seconds);
            }
            vm.warp(block.timestamp + 24 hours + 1 seconds);
        }
    }

    function _testRevertSwapVolumeLimitExceeded(bool lite) internal {
        uint256 amount = 100;
        uint256 iters = 3;

        uint256 volumeLimit = amount * iters;
        VolumeLimitedPair pair = new VolumeLimitedPair(
            address(tokenA),
            address(tokenB),
            volumeLimit
        );

        for (uint256 j = 0; j < iters; j++) {
            PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
            callSwap(pair, address(tokenA), address(tokenB), amount, lite);
            assertEq(tokenA.balanceOf(address(this)), 0);
            assertEq(tokenB.balanceOf(address(pair)), 0);
            vm.warp(block.timestamp + 1 seconds);
        }

        PairTestLib.prepareSwap(pair, tokenA, tokenB, amount);
        vm.expectRevert(VolumeLimitExceeded.selector);
        callSwap(pair, address(tokenA), address(tokenB), amount, lite);
    }

    function testSwap() public {
        _testSwap(false);
    }

    function testRevertSwapVolumeLimitExceeded() public {
        _testRevertSwapVolumeLimitExceeded(false);
    }

    function testSwapLite() public {
        _testSwap(true);
    }

    function testRevertSwapLiteVolumeLimitExceeded() public {
        _testRevertSwapVolumeLimitExceeded(true);
    }

    function testSwap24HoursIn() public {
        vm.warp(24 hours);
        _testSwap(false);
    }

    function testRevertSwapVolumeLimitExceeded24HoursIn() public {
        vm.warp(24 hours);
        _testRevertSwapVolumeLimitExceeded(false);
    }
}
