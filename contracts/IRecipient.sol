// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.7.6;

interface IRecipient {
    //change delegate
    function changeDelegate(address _newDelegate);
    //for receiving erc20 tokens
    function receive(address token, uint amount);
    ////when the delegate is changed
    event newDelegate(address indexed newDelegate);
    //when all tokens are wihdrawn
    event withdrawal(address indexed token, uint indexed amount, uint indexed time);
    //when a certain token is received
    event received(address indexed token, uint indexed amount, uint indexed time);
    //swap token
    function swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut, ISwapRouter _swapRouter, uint24 _poolFee);
    /*
        only designated accounts can call this function
        withdraw all assets to delegate address
    */
    function withdrawFees(address tokenOut, ISwapRouter _swapRouter, uint24 _poolFee);
}