// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";

import {Pair, TokenId} from "./Pair.sol";

struct Swap {
    uint256 cumulativeSwappedAmount;
    uint256 timestamp;
}

error RateLimitExceeded();
/**
 * @dev A pair that enforces a limit on the volume of swaps.
 */
contract RateLimitedPair is Pair {
    // The maximum volume of swaps in 24 hours
    uint256 public rateLimit;

    Swap[] internal swaps;
    uint256 internal lastSwapIndexOlderThan24Hours;

    constructor(
        address _tokenAddressA,
        address _tokenAddressB,
        uint256 _rateLimit
    ) Pair(_tokenAddressA, _tokenAddressB) {
        rateLimit = _rateLimit;
    }

    function findLastSwapIndexOlderThan24Hours()
        public
        view
        returns (uint256, bool)
    {
        if (swaps.length == 0) {
            // No swaps
            return (0, false);
        }

        if (lastSwapIndexOlderThan24Hours == 0) {
            if (swaps[0].timestamp > block.timestamp - 24 hours) {
                // No swaps older than 24 hours
                return (0, false);
            }
        }

        if (lastSwapIndexOlderThan24Hours == swaps.length - 1) {
            // All swaps are older than 24 hours
            return (lastSwapIndexOlderThan24Hours, true);
        }

        uint256 lastSwapIndex = swaps.length - 1;
        if (swaps[lastSwapIndex].timestamp < block.timestamp - 24 hours) {
            // All swaps are older than 24 hours
            return (lastSwapIndex, true);
        }

        // Binary search to find the oldest swap in the last 24 hours
        uint256 left = lastSwapIndexOlderThan24Hours + 1;
        uint256 right = lastSwapIndex;

        while (left < right) {
            uint256 mid = left + (right - left) / 2;
            if (swaps[mid].timestamp < block.timestamp - 24 hours) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        return (left - 1, true);
    }

    function enforceRateLimit(uint256 amount) internal {
        uint256 totalSwappedAmountInLast24Hours;
        (uint256 left, bool ok) = findLastSwapIndexOlderThan24Hours();
        if (ok) {
            lastSwapIndexOlderThan24Hours = left;
            uint256 right = swaps.length - 1;
            totalSwappedAmountInLast24Hours =
                swaps[right].cumulativeSwappedAmount -
                swaps[left].cumulativeSwappedAmount;
        }
        if (totalSwappedAmountInLast24Hours + amount > rateLimit) {
            revert RateLimitExceeded();
        }
    }

    function registerSwap(uint256 amount) internal {
        if (swaps.length == 0) {
            swaps.push(Swap(amount, block.timestamp));
        } else {
            Swap memory lastSwap = swaps[swaps.length - 1];
            swaps.push(
                Swap(lastSwap.cumulativeSwappedAmount + amount, block.timestamp)
            );
        }
    }

    function swap(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount
    ) public override {
        enforceRateLimit(amount);
        super.swap(fromTokenAddress, toTokenAddress, amount);
        registerSwap(amount);
    }

    function swapLite(TokenId tokenId, uint256 amount) public override {
        if (tokenId == TokenId.A) {
            swap(address(tokenA), address(tokenB), amount);
        } else {
            swap(address(tokenB), address(tokenA), amount);
        }
    }

    function maxSwap() public view returns (uint256) {
        (uint256 left, bool ok) = findLastSwapIndexOlderThan24Hours();
        if (!ok) {
            return rateLimit;
        }
        uint256 right = swaps.length - 1;
        uint256 totalSwappedAmountInLast24Hours;
        totalSwappedAmountInLast24Hours =
            swaps[right].cumulativeSwappedAmount -
            swaps[left].cumulativeSwappedAmount;
        if (totalSwappedAmountInLast24Hours >= rateLimit) {
            // Check if the rate limit has been exceeded to accomodate an updatable rate limit
            return 0;
        }
        return rateLimit - totalSwappedAmountInLast24Hours;
    }
}
