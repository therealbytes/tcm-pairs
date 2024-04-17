// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Pair} from "./Pair.sol";

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
    uint256 internal oldestSwapInLast24HoursIndex;

    constructor(
        address tokenAddressA,
        address tokenAddressB,
        uint256 rateLimit
    ) Pair(tokenAddressA, tokenAddressB) {
        rateLimit = rateLimit;
    }

    function updateOldestSwapInLast24HoursIndex() internal returns (uint256) {
        // Binary search to find the oldest swap in the last 24 hours
        uint256 left = oldestSwapInLast24HoursIndex;
        uint256 right = swaps.length - 1;
        while (left <= right) {
            uint256 mid = left + (right - left) / 2;
            if (swaps[mid].timestamp < block.timestamp - 24 hours) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        // left points to either the oldest swap in the last 24 hours or the last swap,
        // which might or might not be in the last 24 hours
        oldestSwapInLast24HoursIndex = left;
        return left;
    }

    function enforceRateLimit(uint256 amount) internal {
        uint256 left = updateOldestSwapInLast24HoursIndex();
        uint256 right = swaps.length - 1;
        uint256 totalSwappedAmountInLast24Hours;
        if (left < right) {
            Swap memory leftSwap = swaps[left];
            Swap memory rightSwap = swaps[right];
            totalSwappedAmountInLast24Hours =
                rightSwap.cumulativeSwappedAmount -
                leftSwap.cumulativeSwappedAmount;
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
}
