// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

error InvalidToken();

error InvalidTokenPair();

error TrasferFailed();

enum TokenId {
    A,
    B
}

/**
 * @dev This contract allows two ERC-20 tokens to be exchanged 1-to-1.
 */
contract Pair {
    IERC20 public tokenA;
    IERC20 public tokenB;

    /**
     * @dev Constructor that sets the addresses of the two tokens that can be exchanged.
     */
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

    /**
     * @dev Deposits a token into the contract. Deposited tokens cannot be withdrawn.
     */
    function deposit(uint256 amount, address tokenAddress) public {
        requireValidToken(tokenAddress);
        requireSuccessfulTransfer(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount)
        );
    }

    /**
     * @dev Deposits a token into the contract. Deposited tokens cannot be withdrawn.
     * The token to deposit is determined by the `tokenId` parameter.
     */
    function depositLite(uint256 amount, TokenId tokenId) public {
        if (tokenId == TokenId.A) {
            deposit(amount, address(tokenA));
        } else {
            deposit(amount, address(tokenB));
        }
    }

    /**
     * @dev Exchanges an amount of one token for an equal amount of another token.
     */
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

    /**
     * @dev Exchanges an amount of one token for an equal amount of another token.
     * The tokens to exchange are determined by the `inTokenId` parameter.
     */
    function exchangeLite(uint256 amount, TokenId inTokenId) public {
        if (inTokenId == TokenId.A) {
            exchange(amount, address(tokenA), address(tokenB));
        } else {
            exchange(amount, address(tokenB), address(tokenA));
        }
    }
}
