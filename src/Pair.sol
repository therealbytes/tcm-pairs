// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

struct TokenPair {
    IERC20 tokenA;
    IERC20 tokenB;
}

error InvalidToken();

error InvalidTokenPair();

error TrasferFailed();

// Make two ERC-20 tokens exchangeable 1-to-1.
contract Pair {
    bool public constant A_TO_B = true;

    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor(address tokenAddressA, address tokenAddressB) {
        tokenA = IERC20(tokenAddressA);
        tokenB = IERC20(tokenAddressB);
    }

    function isValidToken(address tokenAddress) public view returns (bool) {
        return
            tokenAddress == address(tokenA) || tokenAddress == address(tokenB);
    }

    function requireValidToken(address tokenAddress) public view {
        if (!isValidToken(tokenAddress)) {
            revert InvalidToken();
        }
    }

    function requireSuccessfulTransfer(bool success) public pure {
        if (!success) {
            revert TrasferFailed();
        }
    }

    function requireValidTokenPair(address a, address b) public view {
        if (!isValidToken(a) || !isValidToken(b)) {
            revert InvalidToken();
        }
        if (a == b) {
            revert InvalidTokenPair();
        }
    }

    function deposit(uint256 amount, address tokenAddress) public {
        requireValidToken(tokenAddress);
        requireSuccessfulTransfer(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount)
        );
    }

    function exchange(
        uint256 amount,
        address fromTokenAddress,
        address toTokenAddress
    ) public {
        requireValidTokenPair(fromTokenAddress, toTokenAddress);
        // Transfer the input tokens from the sender to this contract.
        requireSuccessfulTransfer(
            IERC20(fromTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            )
        );
        // Transfer the output tokens from this contract to the sender.
        requireSuccessfulTransfer(
            IERC20(toTokenAddress).transfer(msg.sender, amount)
        );
    }

    function exchangeLite(uint256 amount, bool aToB) public {
        if (aToB == A_TO_B) {
            exchange(amount, address(tokenA), address(tokenB));
        } else {
            exchange(amount, address(tokenB), address(tokenA));
        }
    }
}
