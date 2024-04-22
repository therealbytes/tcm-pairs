// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {console2} from "forge-std/Test.sol";
import {Pair, TokenId} from "./Pair.sol";

struct Swap {
    uint128 cumulativeSwappedAmount;
    uint128 timestamp;
}

error VolumeLimitExceeded();

/**
 * @dev A pair that enforces a limit on the volume of swaps.
 */
contract VolumeLimitedPair is Pair, ReentrancyGuard {
    // The maximum volume of swaps in 24 hours
    uint256 public volumeLimit;

    Swap[] internal swaps;
    uint256 internal lastSwapIndexOlderThan24Hours;

    /**
     * @dev Constructor initializes the pair with the addresses of the two tokens that can be swapped and sets the volume limit.
     */
    constructor(
        address _tokenAddressA,
        address _tokenAddressB,
        uint256 _volumeLimit
    ) Pair(_tokenAddressA, _tokenAddressB) {
        volumeLimit = _volumeLimit;
    }

    /**
     * @dev Find the index of the last swap older than 24 hours.
     */
    function findLastSwapIndexOlderThan24Hours()
        internal
        view
        returns (uint256, bool)
    {
        if (swaps.length == 0) {
            // No swaps
            return (0, false);
        }
        if (block.timestamp < 24 hours) {
            // Chain is younger than 24 hours so there are no swaps older than 24 hours
            return (0, false);
        }

        uint256 lastSwapIndex = swaps.length - 1;
        if (
            uint256(swaps[lastSwapIndex].timestamp) < block.timestamp - 24 hours
        ) {
            // Last swap is older than 24 hours
            return (lastSwapIndex, true);
        }

        // Binary search to find the oldest swap in the last 24 hours
        uint256 left = lastSwapIndexOlderThan24Hours + 1;
        uint256 right = lastSwapIndex;

        while (left < right) {
            uint256 mid = left + (right - left) / 2;
            if (uint256(swaps[mid].timestamp) < block.timestamp - 24 hours) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        uint256 index = left - 1;
        if (uint256(swaps[index].timestamp) < block.timestamp - 24 hours) {
            return (index, true);
        } else {
            return (0, false);
        }
    }

    function findAndUpdateLastSwapIndexOlderThan24Hours()
        internal
        returns (uint256, bool)
    {
        (uint256 index, bool ok) = findLastSwapIndexOlderThan24Hours();
        if (ok) {
            lastSwapIndexOlderThan24Hours = index;
        }
        return (index, ok);
    }

    function swapVolumeInLast24Hours() internal view returns (uint256) {
        if (swaps.length == 0) {
            return 0;
        }
        uint256 cumulativeSwappedAmount24HoursAgo;
        (uint256 left, bool ok) = findLastSwapIndexOlderThan24Hours();
        if (ok) {
            cumulativeSwappedAmount24HoursAgo = uint256(
                swaps[left].cumulativeSwappedAmount
            );
        }
        uint256 right = swaps.length - 1;
        return
            uint256(swaps[right].cumulativeSwappedAmount) -
            cumulativeSwappedAmount24HoursAgo;
    }

    /**
     * @dev Enforce the volume limit on the volume of swaps.
     */
    function enforcevolumeLimit(uint256 amount) internal {
        uint256 totalSwappedAmountInLast24Hours;
        if (swaps.length == 0) {
            totalSwappedAmountInLast24Hours = 0;
        } else {
            uint256 cumulativeSwappedAmount24HoursAgo;
            (
                uint256 left,
                bool ok
            ) = findAndUpdateLastSwapIndexOlderThan24Hours();
            if (ok) {
                cumulativeSwappedAmount24HoursAgo = uint256(
                    swaps[left].cumulativeSwappedAmount
                );
            }
            uint256 right = swaps.length - 1;
            totalSwappedAmountInLast24Hours =
                uint256(swaps[right].cumulativeSwappedAmount) -
                cumulativeSwappedAmount24HoursAgo;
        }
        if (totalSwappedAmountInLast24Hours + amount > volumeLimit) {
            revert VolumeLimitExceeded();
        }
    }

    /**
     * @dev Register a swap.
     */
    function registerSwap(uint256 amount) internal {
        if (swaps.length == 0) {
            swaps.push(Swap(uint128(amount), uint128(block.timestamp)));
        } else {
            Swap memory lastSwap = swaps[swaps.length - 1];
            swaps.push(
                Swap(
                    lastSwap.cumulativeSwappedAmount + uint128(amount),
                    uint128(block.timestamp)
                )
            );
        }
    }

    /**
     * @dev Swap tokens.
     */
    function swap(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount
    ) public override nonReentrant {
        enforcevolumeLimit(amount);
        super.swap(fromTokenAddress, toTokenAddress, amount);
        registerSwap(amount);
    }

    /**
     * @dev Swap tokens. The token to swap is determined by the `tokenId` parameter.
     */
    function swapLite(TokenId fromTokenId, uint256 amount) public override {
        if (fromTokenId == TokenId.A) {
            swap(address(tokenA), address(tokenB), amount);
        } else {
            swap(address(tokenB), address(tokenA), amount);
        }
    }

    /**
     * @dev Get the maximum amount that can be swapped at the current time and volume limit.
     */
    function maxSwap() public view returns (uint256) {
        uint256 volume = swapVolumeInLast24Hours();
        if (volume >= volumeLimit) {
            // Check if the volume limit has been exceeded to accomodate an updatable volume limit
            return 0;
        }
        return volumeLimit - volume;
    }
}
