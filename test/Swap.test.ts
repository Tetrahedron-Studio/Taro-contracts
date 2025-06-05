
import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import { ISwapRouter, IERC20, Swap, IRecipient } from "../typechain-types";

describe("Swap Contract", function () {
  let swap: Contract;
  let owner: Signer;
  let user: Signer;
  let feeRecipient: Contract;
  let tokenIn: Contract;
  let tokenOut: Contract;
  let swapRouter: Contract;

  const feeBps = 100; // 1%

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy dummy tokens
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    tokenIn = await ERC20Mock.deploy("TokenIn", "TIN", ethers.utils.parseEther("1000000"));
    tokenOut = await ERC20Mock.deploy("TokenOut", "TOUT", ethers.utils.parseEther("1000000"));

    // Deploy dummy fee recipient (mock implementation)
    const FeeRecipientMock = await ethers.getContractFactory("FeeRecipientMock");
    feeRecipient = await FeeRecipientMock.deploy();

    // Deploy dummy swap router
    const SwapRouterMock = await ethers.getContractFactory("SwapRouterMock");
    swapRouter = await SwapRouterMock.deploy(tokenIn.address, tokenOut.address);

    // Deploy Swap contract
    const Swap = await ethers.getContractFactory("Swap");
    swap = await Swap.deploy(
      swapRouter.address,
      feeBps,
      feeRecipient.address
    );
  });

  describe("Deployment", function () {
    it("should set the correct initial feeRecipient and feeBps", async function () {
      expect(await swap.feeRecipient()).to.equal(feeRecipient.address);
      expect(await swap.feeBps()).to.equal(feeBps);
    });
  });

  describe("Swap Functionality", function () {
    const amountIn = ethers.utils.parseEther("1000");
    const expectedOut = ethers.utils.parseEther("900");

    beforeEach(async function () {
      // Transfer tokens to user
      await tokenIn.transfer(await user.getAddress(), amountIn.mul(2));
      // Approve the swap contract
      await tokenIn.connect(user).approve(swap.address, amountIn.mul(2));
    });

    it("should deduct fee and execute swap", async function () {
      const feeAmount = amountIn.mul(feeBps).div(10000);
      const netAmount = amountIn;

      // Execute swap
      await expect(
        swap.connect(user).swap(tokenIn.address, tokenOut.address, amountIn, expectedOut)
      ).to.emit(swap, "SwapExecuted");

      // Check balances
      const feeRecipientBalance = await tokenIn.balanceOf(feeRecipient.address);
      expect(feeRecipientBalance).to.equal(feeAmount);

      const userOutBalance = await tokenOut.balanceOf(await user.getAddress());
      expect(userOutBalance).to.equal(expectedOut);
    });

    it("should revert if minAmountOut is not met", async function () {
      await expect(
        swap.connect(user).swap(tokenIn.address, tokenOut.address, amountIn, expectedOut.mul(2))
      ).to.be.revertedWith("Mock: insufficient output amount");
    });
  });

  describe("Admin Functions", function () {
    it("should allow the owner to change the fee", async function () {
      const newFee = 200;
      await expect(swap.setFee(newFee))
        .to.emit(swap, "FeeChanged")
        .withArgs(feeBps, newFee, await ethers.provider.getBlockNumber());
      expect(await swap.feeBps()).to.equal(newFee);
    });

    it("should allow the owner to change the fee recipient", async function () {
      const newRecipient = swap.address; // Just for test
      await expect(swap.setFeeRecipient(newRecipient))
        .to.emit(swap, "recipientChanged")
        .withArgs(feeRecipient.address, newRecipient, await ethers.provider.getBlockNumber());
      expect(await swap.feeRecipient()).to.equal(newRecipient);
    });

    it("should allow pause/unpause", async function () {
      await swap.pause();
      expect(await swap.paused()).to.be.true;
      await swap.unpause();
      expect(await swap.paused()).to.be.false;
    });

    it("should allow the owner to rescue tokens", async function () {
      const rescueAmount = ethers.utils.parseEther("1000");
      await tokenIn.transfer(swap.address, rescueAmount);
      await swap.rescueTokens(tokenIn.address, await owner.getAddress(), rescueAmount);
      const ownerBalance = await tokenIn.balanceOf(await owner.getAddress());
      expect(ownerBalance).to.be.gte(rescueAmount);
    });

    it("should prevent non-owners from calling admin functions", async function () {
      await expect(swap.connect(user).setFee(200)).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(swap.connect(user).pause()).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(swap.connect(user).rescueTokens(tokenIn.address, await user.getAddress(), 100)).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
