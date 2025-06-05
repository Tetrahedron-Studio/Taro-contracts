// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract FeeRecipientMock is Ownable,ReentrancyGuard {
    using SafeERC20 for IERC20;
    /*
    a mapping of all the tokens this contract holds and thier balance
    token address -> balance
    */
    mapping(address => uint) public tokens;
    mapping(address => bool) public tokenExist;
    //an array containing the list of all tokens this contract holds
    address[] public tokens_list;
    //the address of the EOA that can withdraw all tokens
    address public delegate;
    //when the delegate is changed
    event newDelegate(address indexed newDelegate);
    //when a certain token is received
    event received(address indexed token, uint indexed amount, uint indexed time);
    //when all tokens are wihdrawn
    event withdrawal(address indexed token, uint indexed amount, uint indexed time);

    constructor() Ownable() {
        delegate = msg.sender;
    }

    function changeDelegate(address _newDelegate) public onlyOwner {
        //change delegate
        require(_newDelegate != address(0), "Invalid delegate address");
        delegate = _newDelegate;
        emit newDelegate(delegate);
    }

    function receiveToken(address _token, uint amount) public {
        //for receiving erc20 tokens
        require(_token != address(0));
        //an interface for the token to be received
        IERC20 token = IERC20(_token);
        //safeTransfer token from msg.sender
        token.safeTransferFrom(msg.sender, address(this), amount);
        //update the balance of the token sent
        tokens[_token] += amount;
        //update the list of tokens held
        //logically if the balance of the token is equal to amount sent, this contract hasn't held that token before
        if (!tokenExist[_token]) {
            tokens_list.push(_token);
            tokenExist[_token] = true;
        }
        //emit event of token receival
        emit received(_token, amount, block.timestamp);
    }

    function swap(address tokenIn, address tokenOut, uint amountIn, uint minAmountOut, ISwapRouter _swapRouter, uint24 _poolFee) internal returns(uint amountOut) {
        //require(_swapRouter != address(0), "Invalid swapRouter");
        //_swapRouter parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: _poolFee,
            recipient: delegate,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut,
            sqrtPriceLimitX96: 0
        });

        IERC20(tokenIn).safeApprove(address(_swapRouter), 0);
        IERC20(tokenIn).safeApprove(address(_swapRouter), amountIn);
        //swap the token
        amountOut = _swapRouter.exactInputSingle(params);
    }

    function withdrawFees(address tokenOut, ISwapRouter _swapRouter, uint24 _poolFee) public onlyOwner nonReentrant {
        /*
        only designated accounts can call this function
        withdraw all assets to delegate address
        */
        //var for storing total amount of tokenOut token received after swapping the contracts portfolio
        uint total;
         
        if (tokens_list.length == 1) {
            //if contract holds one token
            uint amountOut = swap(tokens_list[0], tokenOut, tokens[tokens_list[0]], 0, _swapRouter, _poolFee);
            emit withdrawal(tokenOut, amountOut, block.timestamp);
            //update token balance to 0
            tokens[tokens_list[0]] = 0;
            //delete token address
            delete tokenExist[tokens_list[0]];
            delete tokens_list;
        } else if (tokens_list.length > 1){
            //if contract holds multiple tokens
            for(uint i = 0; i < tokens_list.length; i++) {
                total += swap(tokens_list[i], tokenOut, tokens[tokens_list[i]], 0, _swapRouter, _poolFee);
                //update token balance to 0
                tokens[tokens_list[i]] = 0;
                delete tokenExist[tokens_list[i]];
            }
            
            delete tokens_list;
            emit withdrawal(tokenOut, total, block.timestamp);
        }
    }
}