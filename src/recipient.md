
# recipient.sol – Documentation

## Overview

The recipient contract acts as a fee collection and withdrawal hub for ERC20 tokens. It can safely receive tokens, track balances, and swap collected tokens into a desired output token using Uniswap V3, then transfer them to a designated delegate address. The contract is owner-controlled, supports secure withdrawals, and is compatible with automated fee pipelines.

---

## Key Components

### Inheritance & Imports

- **Ownable**: Restricts certain functions to the contract owner.
- **ReentrancyGuard**: Protects against reentrancy attacks.
- **SafeERC20**: Ensures safe ERC20 operations.
- **IERC20**: Standard ERC20 interface.
- **ISwapRouter**: Uniswap V3 router interface.

---

### State Variables

- `tokens (mapping)`: Tracks the balance of each ERC20 token held.
- `tokenExist (mapping)`: Tracks whether a token address is registered.
- `tokens_list (address[])`: List of all unique tokens held by the contract.
- `delegate`: The address authorized to receive withdrawn tokens (can be changed by the owner).

---

### Events

- `newDelegate`: Emitted when the delegate address changes.
- `received`: Emitted whenever tokens are received.
- `withdrawal`: Emitted whenever tokens are withdrawn (after swap).

---

### Constructor

- Sets the deploying account as the initial delegate.

---

### Core Logic

#### changeDelegate(address _newDelegate)

- Owner-only. Sets a new delegate address for withdrawals.

#### receiveToken(address _token, uint amount)

- Anyone can call.
- Receives specified ERC20 tokens from the sender.
- Updates internal balance and tokens list.
- Emits a received event.

#### swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut, ISwapRouter _swapRouter, uint24 _poolFee) → uint

- Internal function.
- Swaps amountIn of tokenIn for tokenOut using Uniswap V3, sending output to the delegate.
- Uses approve pattern for security.
- Returns the amount of tokenOut received.

#### withdrawFees(address tokenOut, ISwapRouter _swapRouter, uint24 _poolFee)

- Owner-only, non-reentrant.
- Withdraws all held tokens, swapping each into tokenOut via Uniswap V3, sending results to the delegate.
- Handles both single- and multi-token portfolios.
- Cleans up internal tracking for each token withdrawn.
- Emits a withdrawal event.

---

## Security & Best Practices

- Uses SafeERC20 for all token operations.
- Protects withdrawal logic with nonReentrant.
- Only the contract owner can change delegate or withdraw tokens.
- Carefully manages token approvals to prevent race conditions.
- Tracks tokens held for efficient portfolio management and auditing.

---

## Notes & Potential Improvements

- `receiveToken` expects the sender to have approved this contract for the specified amount.
- The contract does not natively support receiving ETH.
- All swaps are performed via Uniswap V3 and require an external router and pool fee to be supplied.
- Withdrawals consolidate tokens into a single token of choice for flexible treasury management.

---

## Summary

The recipient contract is a secure and flexible fee collector and swapper for ERC20 tokens. It supports automated fee collection, multi-token portfolio management, and safe conversion to a target asset for onward distribution. Its design is modular, secure, and easily extensible for DeFi integrations.
