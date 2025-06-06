
# ISwap.sol – Documentation

## Overview

The ISwap interface defines the required structure for any Swap contract implementation. It standardizes key functions and events for token swaps, fee management, and administrative actions, ensuring interoperability and consistent behavior across contracts that adopt this interface.

---

## Interface Elements

### Events

- **SwapExecuted**
  - Triggered after a swap.
  - Parameters:
    - `user`: The address that initiated the swap.
    - `tokenIn`: The ERC20 token given.
    - `tokenOut`: The ERC20 token received.
    - `amountIn`: Amount of tokenIn swapped.
    - `amountOut`: Amount of tokenOut received.
    - `feeAmount`: Fee charged for the swap.
    - `time`: Timestamp of the swap.

- **FeeChanged**
  - Triggered when the swap fee is changed.
  - Parameters:
    - `oldFee`: Previous fee value.
    - `newFee`: New fee value.
    - `time`: Timestamp of the change.

- **recipientChanged**
  - Triggered when the fee recipient address is changed.
  - Parameters:
    - `oldRecipient`: Previous fee recipient.
    - `newRecipient`: New fee recipient.
    - `time`: Timestamp of the change.

---

### Functions

- **getFee(uint amount) external**
  - Returns the fee for a given input amount.

- **swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut) external**
  - Swaps amountIn of `tokenIn` for at least `minAmountOut` of `tokenOut`.

- **setFee(uint newFee) external**
  - Changes the swap fee to `newFee`.

- **setFeeRecipient(address newRecipient) external**
  - Changes the address that receives fees to `newRecipient`.

---

## Usage

- Any contract implementing ISwap must provide concrete logic for all declared functions and must emit the specified events as appropriate.
- Adopting this interface allows for plug-and-play compatibility with other contracts or systems expecting ISwap-compliant behavior.

---

## Summary

ISwap.sol is a core interoperability interface for swap contracts. It standardizes swap execution, fee management, and admin controls, making it easier to build modular, composable DeFi systems.
