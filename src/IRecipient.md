
# IRecipient.sol – Documentation

## Overview

The `IRecipient` interface standardizes the required structure and behavior for recipient contracts that manage ERC20 token collection, delegation, and withdrawal. It defines functions and events for handling incoming tokens, managing delegates, performing swaps through Uniswap V3, and withdrawing tokens. Contracts implementing `IRecipient` allow for modular, interoperable fee collection and treasury management in DeFi systems.

---

## Interface Elements

### Functions

- **changeDelegate(address _newDelegate) external**
  - Changes the delegate address authorized to receive withdrawn tokens.

- **receiveToken(address token, uint amount) external**
  - Allows the contract to receive a specified amount of an ERC20 token.

- **swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut, ISwapRouter _swapRouter, uint24 _poolFee) external**
  - Swaps a specified amount of `tokenIn` for `tokenOut` via Uniswap V3 using the provided router and pool fee.

- **withdrawFees(address tokenOut, ISwapRouter _swapRouter, uint24 _poolFee) external**
  - Withdraws all held tokens, converting them into `tokenOut` via Uniswap V3, and sends the output to the delegate address.

---

### Events

- **newDelegate(address indexed newDelegate)**
  - Emitted when the delegate address is changed.

- **withdrawal(address indexed token, uint indexed amount, uint indexed time)**
  - Emitted when tokens are withdrawn from the contract.

- **received(address indexed token, uint indexed amount, uint indexed time)**
  - Emitted whenever tokens are received by the contract.

---

## Usage

- Any contract implementing `IRecipient` must provide actual logic for all declared functions and emit the specified events at the appropriate times.
- This interface ensures that recipient contracts can safely collect tokens, assign a delegate for withdrawals, perform swaps, and notify observers of key actions.
- Adopting this interface allows for seamless integration into broader DeFi, fee distribution, or treasury management systems where standardized recipient behavior is required.

---

## Summary

`IRecipient.sol` is a core interoperability interface for modular DeFi recipient contracts. It ensures that contracts can collect, manage, and withdraw ERC20 tokens securely and flexibly, supporting both direct transfers and automated swaps through Uniswap V3.