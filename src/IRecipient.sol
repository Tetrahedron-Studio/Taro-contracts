// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.7.6;
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IRecipient {
    //change delegate
    function changeDelegate(address _newDelegate) external;
    //for receiving erc20 tokens
    function receiveToken(address token, uint amount) external;
    ////when the delegate is changed
    event newDelegate(address indexed newDelegate);
    //when all tokens are wihdrawn
    event withdrawal(address indexed token, uint indexed amount, uint indexed time);
    //when a certain token is received
    event received(address indexed token, uint indexed amount, uint indexed time);
    //swap token
    function swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut, ISwapRouter _swapRouter, uint24 _poolFee) external;
    /*
        only designated accounts can call this function
        withdraw all assets to delegate address
    */
    function withdrawFees(address tokenOut, ISwapRouter _swapRouter, uint24 _poolFee) external;
}