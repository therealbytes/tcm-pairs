// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

error InvalidToken();

error InvalidTokenPair();

error TransferFailed();

enum TokenId {
    A,
    B
}

/**
 * @dev This contract allows two ERC-20 tokens to be swapped 1-to-1.
 */
contract Pair {
    event Deposited(address indexed token, uint256 amount);

    event Swapped(
        address indexed fromToken,
        address indexed toToken,
        uint256 amount
    );

    IERC20 public tokenA;
    IERC20 public tokenB;

    /**
     * @dev Constructor that sets the addresses of the two tokens that can be swapped.
     */
    constructor(address _tokenAddressA, address _tokenAddressB) {
        tokenA = IERC20(_tokenAddressA);
        tokenB = IERC20(_tokenAddressB);
    }

    function isValidToken(address tokenAddress) internal view returns (bool) {
        return
            tokenAddress == address(tokenA) || tokenAddress == address(tokenB);
    }

    function requireValidToken(address tokenAddress) internal view {
        if (!isValidToken(tokenAddress)) {
            revert InvalidToken();
        }
    }

    function requireSuccessfulTransfer(bool success) internal pure {
        if (!success) {
            revert TransferFailed();
        }
    }

    function requireValidTokenPair(address a, address b) internal view {
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
    function deposit(address tokenAddress, uint256 amount) public virtual {
        requireValidToken(tokenAddress);
        requireSuccessfulTransfer(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount)
        );
        emit Deposited(tokenAddress, amount);
    }

    /**
     * @dev Deposits a token into the contract. Deposited tokens cannot be withdrawn.
     * The token to deposit is determined by the `tokenId` parameter.
     */
    function depositLite(TokenId tokenId, uint256 amount) public virtual {
        if (tokenId == TokenId.A) {
            deposit(address(tokenA), amount);
        } else {
            deposit(address(tokenB), amount);
        }
    }

    /**
     * @dev Swaps an amount of one token for an equal amount of another token.
     */
    function swap(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount
    ) public virtual {
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
        emit Swapped(fromTokenAddress, toTokenAddress, amount);
    }

    /**
     * @dev Swaps an amount of one token for an equal amount of another token.
     * The tokens to swap are determined by the `inTokenId` parameter.
     */
    function swapLite(TokenId inTokenId, uint256 amount) public virtual {
        if (inTokenId == TokenId.A) {
            swap(address(tokenA), address(tokenB), amount);
        } else {
            swap(address(tokenB), address(tokenA), amount);
        }
    }
}
