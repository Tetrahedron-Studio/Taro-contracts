// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Swap is Ownable, ReentrancyGuard, Pausable{
    using SafeERC20 for IERC20;
    //swapRouter
    ISwapRouter public immutable swapRouter;
    //the address where fees are paid to
    address public feeRecipient;
    //the percentage charged as fee
    uint public feeBps;
    //poolfee might still be changed later
    uint24 public constant poolFee = 3000;

    //for when a swap is executed
    event SwapExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint feeAmount, uint time);
    //when the fee is changed
    event FeeChanged(uint indexed oldFee, uint indexed newFee, uint indexed time);
    //when the receivin addrees for fees is changed
    event recipientChanged(address indexed oldRecipient, address indexed newRecipient, uint indexed time);

    constructor(ISwapRouter _swapRouter, uint _feeBps, address _feeRecipient) Ownable () {
        swapRouter = _swapRouter;
        //ensure fee recipient is a contract
        require(Address.isContract(_feeRecipient), "Fee Recipient must be a contract");
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
    }

    function getFee(uint amount) internal view returns(uint fee){
        //returns the fee for the certain amount passed
        fee = (amount * feeBps) / 10000;
    }

    function swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut) external payable nonReentrant whenNotPaused returns(uint amountOut){
        //swaps tokens

        /* 
        fee -> get the fee using getFee()
        tokenIn is the token being swapped for another token
        tokenOut is the token tokenIn is swapped for
        Transfer amountIn of tokenIn and the fee from the user's balance, but the user has to safeApprove from his own end
        */
        uint fee = getFee(amountIn);
        IERC20 token2 = IERC20(tokenOut);
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn + fee);
        
        /*
        recipient -> is the interface for the address where the fees go
        it has a function called  receiveToken which safeTransfers the specified amount of the specified token from the caller
        this contract has to safeApprove feeRecipient for spending of the fee so that the receive function will work 
        */
        IRecipient recipient = IRecipient(feeRecipient);
        IERC20(tokenIn).safeApprove(feeRecipient, 0);
        IERC20(tokenIn).safeApprove(feeRecipient, fee);
        recipient.receiveToken(address(token1), fee);
        
        //safeApprove the swapRouter for spending of amountIn
        IERC20(tokenIn).safeApprove(address(swapRouter), 0);
        IERC20(tokenIn).safeApprove(address(swapRouter), amountIn);

        //parameters for the swapRouter
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut,//this is the minimum amount of tokenOut that should be received.
            sqrtPriceLimitX96: 0 
        });

        //execute the swap, amountOut stores the amount of tokenOut that is received after the swap
        amountOut = swapRouter.exactInputSingle(params);

        //safeTransfer tokenOut to the user who called and emit an event for the swap
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut, fee, block.timestamp);
    }

    //admin functions

    //change the fees
    function setFee(uint newFee) public onlyOwner {
        uint oldfee = feeBps;
        feeBps = newFee;
        emit FeeChanged(oldfee, newFee, block.timestamp);
    }

    //change the address that receives fees
    function setFeeRecipient(address newRecipient) public onlyOwner {
        address old = feeRecipient;
        require(Address.isContract(newRecipient), "Fee Recipient must be a contract");
        feeRecipient = newRecipient;
        emit recipientChanged(old, newRecipient, block.timestamp);
    }

    //pause mechanisms
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //send all leftover tokens to Fee recipient 
    function rescueTokens(address token, address to, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}