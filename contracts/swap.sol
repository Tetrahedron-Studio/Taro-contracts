// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IRecipient.sol";

contract Swap is Ownable, ReentrancyGuard{
    //swapRouter
    ISwapRouter public immutable swapRouter;
    //the address where fees are paid to
    address public feeRecipient;
    //the percentage charged as fee
    uint public feeBps;
    //poolfee might still be changed later
    uint public constant poolFee = 3000;

    //for when a swap is executed
    event SwapExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint feeAmount, uint time);
    //when the fee is changed
    event FeeChanged(uint indexed oldFee, uint indexed newFee, uint indexed time);
    //when the receivin addrees for fees is changed
    event recipientChanged(address indexed oldRecipient, address indexed newRecipient, uint indexed time);

    constructor(ISwapRouter _swapRouter, uint _feeBps, uint _feeRecipient) Ownable () {
        swapRouter = _swapRouter;
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
    }

    function getFee(uint amount) internal returns(uint fee) {
        //returns the fee for the certain amount passed
        fee = amount * _feeBps;
    }

    function swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut) external payable nonReentrant returns(uint amountOut){
        //swaps tokens

        /* 
        fee -> get the fee using getFee()
        token1 and token2 are the interfaces for tokenIn and tokenOut respectively
        checks if the user that called this function has enough of tokenIn to swap
        transfer amountIn of token1 and the fee from the user's balance, but the user has to approve from his own end
        */
        uint fee = getFee(amountIn);
        IERC20 token1 = IERC20(tokenIn);
        IERC20 token2 = IERC20(tokenOut);
        require(IERC20.balanceOf(msg.sender) >= amountIn);
        token1.transferFrom(msg.sender, address(this), amountIn + fee);
        
        /*
        recipient -> is the interface for the address where the fees go
        it has a function called  receive which transfers the specified amount of the specified token from the caller
        this contract has to approve feeRecipient for spending of the fee so that the receive function will work 
        */
        IRecipient recipient = IRecipient(feeRecipient);
        recipient.receive(token1, fee)
        token1.approve(feeRecipient, fee);
        
        //approve the swapRouter for spending of amountIn
        token1.approve(address(swapRouter), amountIn);

        //parameters for the swapRouter
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOutMinimum: minAmountOut,//this is the minimum amount of tokenOut that should be received.
            sqrtPriceLimitX96: 0 //dont know wha this does; yet.
        })

        //execute the swap, amountOut stores the amount of tokenOut that is received after the swap
        uint amountOut = swapRouter.exactInputSingle(params);

        if(amountOut < minAmountOut) {
            //does something if amountOut is less than minAmountOut maybe a refund
        }

        //transfer token2 to the user who called and emit an event for the swap
        token2.transfer(msg.sender, amountOut);
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut, fee, block.timestamp);
    }

    //admin functions
    function setFee(uint newFee) public onlyOwner {
        //change the fee
        oldfee = feeBps;
        feeBps = newFee;
        emit FeeChanged(oldfee, newFee, block.timestamp);
    }

    function setFeeRecipient(address newRecipient) public onlyOwner {
        //change the address that receives fees
        address old = feeRecipient;
        feeRecipient = newRecipient;
        emit recipientChanged(old, newRecipient, block.timestamp);
    }
}