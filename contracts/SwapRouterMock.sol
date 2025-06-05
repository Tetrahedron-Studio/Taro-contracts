// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract SwapRouterMock is ISwapRouter {
    address public tokenIn;
    address public tokenOut;
    uint256 public rate; // How many tokenOut per tokenIn

    constructor(address _tokenIn, address _tokenOut) {
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        rate = 1e18; // 1:1 rate by default
    }

    function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
     ) external override {
    // Mock implementation; do nothing
}


    function setRate(uint256 _rate) external {
        rate = _rate;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        override
        payable
        returns (uint256 amountOut)
    {
        IERC20 tokenInContract = IERC20(params.tokenIn);
        IERC20 tokenOutContract = IERC20(params.tokenOut);

        // Take tokens from caller (the Swap contract)
        require(tokenInContract.transferFrom(msg.sender, address(this), params.amountIn), "Mock: tokenIn transfer failed");

        // Calculate output based on rate
        amountOut = (params.amountIn * rate) / 1e18;

        require(amountOut >= params.amountOutMinimum, "Mock: insufficient output amount");

        // Send tokenOut back to msg.sender (the Swap contract)
        require(tokenOutContract.transfer(msg.sender, amountOut), "Mock: tokenOut transfer failed");
    }

    // Stubs to satisfy interface
    function exactInput(ExactInputParams calldata) external override payable returns (uint256) {
        revert("Not implemented");
    }

    function exactOutputSingle(ExactOutputSingleParams calldata) external override payable returns (uint256) {
        revert("Not implemented");
    }

    function exactOutput(ExactOutputParams calldata) external override payable returns (uint256) {
        revert("Not implemented");
    }

    receive() external payable {}
}
