
# swap.sol – Documentation

## Overview

This contract, `Swap`, acts as a swap proxy using the Uniswap V3 router. It allows users to swap ERC20 tokens while charging a configurable fee. The contract owner can pause the contract, change the fee, and update the fee recipient. The contract also includes security features (`ReentrancyGuard`, `Pausable`) and uses OpenZeppelin libraries for safety.

---

## Key Components

### Inheritance & Imports

- **Ownable**: Access control for owner-only functions.
- **ReentrancyGuard**: Prevents reentrancy attacks.
- **Pausable**: Allows pausing critical functions in emergencies.
- **ISwapRouter** (Uniswap V3): For executing swaps.
- **IERC20**, **SafeERC20** (OpenZeppelin): Secure ERC20 token handling.
- **Address**: For contract address checks.
- **IRecipient**: Custom interface for fee processing.

---

### State Variables

- `swapRouter`: The Uniswap V3 router contract address (immutable).
- `feeRecipient`: Address (must be a contract) that receives swap fees.
- `feeBps`: Fee in basis points (1 basis point = 0.01%).
- `poolFee`: Constant, set at 3000 (0.3%) for Uniswap pool fee.

---

### Events

- `SwapExecuted`: Emitted after each swap, logs user, tokens, amounts, fee, and time.
- `FeeChanged`: Emitted when the fee basis points are changed.
- `recipientChanged`: Emitted when the fee recipient address changes.

---

### Constructor

- Sets the Uniswap router, fee recipient, and fee.
- Checks that the fee recipient is a contract.

---

### Core Logic

#### getFee(uint amount) → uint

- Internal view function. Calculates the fee for a given amount:  
  `(amount * feeBps) / 10000`.

#### swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut) → uint

- Main swap function. Steps:
  1. Calculates the fee for `amountIn`.
  2. Transfers `amountIn + fee` from the user to the contract.
  3. Approves `feeRecipient` for only the fee amount and calls its `receiveToken` function.
  4. Approves the Uniswap router for `amountIn`.
  5. Constructs swap parameters (`ExactInputSingleParams`).
  6. Calls Uniswap router’s `exactInputSingle` to perform the swap.
  7. Transfers the swapped `tokenOut` to the user.
  8. Emits a `SwapExecuted` event.

- Security: Uses `nonReentrant` and `whenNotPaused` modifiers. `SafeERC20` for all transfers.

#### Admin Functions

- `setFee(uint newFee)`: Only owner can change `feeBps`.
- `setFeeRecipient(address newRecipient)`: Only owner. Must be a contract.
- `pause()` and `unpause()`: Owner can pause/unpause the contract.
- `rescueTokens(address token, address to, uint amount)`: Owner can rescue any ERC20 token to a target address.

---

## Security & Best Practices

- Uses OpenZeppelin’s `SafeERC20` and `Address` for secure transfers and contract checks.
- Uses `ReentrancyGuard` to prevent reentrancy attacks.
- Uses `Pausable` to allow the owner to pause swaps in emergencies.
- Uses `immutable` and `constant` for key addresses and parameters.
- All approvals set to 0 before resetting to a new amount (prevents race conditions).

---

## Notes & Potential Improvements

- Fee recipient must implement the `IRecipient` interface with a `receiveToken` function.
- The pool fee is fixed at 3000 (Uniswap’s 0.3%). If variable pool fees are needed, this would need an update.
- The swap function does not support multi-hop swaps (only direct `tokenIn` → `tokenOut`).
- Fee is charged in `tokenIn`, not `tokenOut`.

---

## Summary

This `Swap` contract safely and flexibly allows users to swap ERC20 tokens via Uniswap V3, with a fee system and strong owner/admin controls. It follows security best practices and is modular for integration with other contracts/services.
