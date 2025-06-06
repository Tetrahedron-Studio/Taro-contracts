// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

interface ISwap {
    //for when a swap is executed
    event SwapExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint feeAmount, uint time);
    //for when the fee is changed
    event FeeChanged(uint indexed oldFee, uint indexed newFee, uint indexed time);
    //when the receiving addrees for fees is changed
    event recipientChanged(address indexed oldRecipient, address indexed newRecipient, uint indexed time);
    //returns the fee for the certain amount passed
    function getFee(uint amount) external;
    //swaps tokens
    function swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut) external;
    //change the fee
    function setFee(uint newFee) external;
    //change the address that receives fees
    function setFeeRecipient(address newRecipient) external;
}