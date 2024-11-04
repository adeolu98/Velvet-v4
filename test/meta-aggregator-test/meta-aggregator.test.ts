import BigNumber from "bignumber.js";
import { expect } from "chai";
import { ethers } from "hardhat";
import { setupTest } from "./fixture";
import{
    loadFixture,
  } from "@nomicfoundation/hardhat-network-helpers";

describe("Swap test", function () {
    it("Swap tokens to tokens", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const balanceUserToken1 = await token1.balanceOf(user.address);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceUserToken2 = await token2.balanceOf(user.address);
        expect(balanceUserToken2).to.be.equal(0);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.address);
        expect(balanceAggregatorToken1).to.be.equal(0)

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, aggregator.address, swapData.data || "", token1Amount, token2Amount, user.address, false)


        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userToken1Balance = await token1.balanceOf(user.address);
        expect(userToken1Balance).to.be.equal(0);
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address);
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
        const aggregatorToken2Balance = await token2.balanceOf(aggregator.address);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap ETH to token", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregator).to.be.equal(0);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const tnx = await metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, aggregator.address, swapData.data || "", nativeTokenAmount, token2Amount, user.address, false, { value: nativeTokenAmount })

        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }


        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const ethBalanceOfAggregatorAfterSwap = await ethers.provider.getBalance(aggregator.address);
        expect(Number(ethBalanceOfAggregatorAfterSwap.sub(ethBalanceOfAggregator))).to.be.equal(nativeTokenAmount);

    })


    it("Swap token to ETH", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


       

        const tx = await executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });


        await token1.mint(user.address, token1Amount);

        const balanceUserToken1 = await token1.balanceOf(user.address);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregator).to.be.equal(nativeTokenAmount);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.address);
        expect(balanceAggregatorToken1).to.be.equal(0)
        const ethBalanceUser = await ethers.provider.getBalance(user.address);



        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount);

        let tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait()

        let tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);
        let approveTnxGasCost;
        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {

            approveTnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0);
        }


        tnx = await metaAggregatorTestManager.connect(user).swap(token1.address, nativeToken, aggregator.address, swapData.data || "", token1Amount, nativeTokenAmount, user.address, false)
        await tnx.wait();

        tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUserAfterSwap.toString()).minus(BigNumber(ethBalanceUser.toString())).plus(tnxGasCost).plus(BigNumber(approveTnxGasCost || 0)).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address)
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
    })

    it("Swap token to ETH receiver is contract", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


       executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });


        await token1.mint(receiverContract.address, token1Amount);

        const balanceReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceReceiverContractToken1).to.be.equal(token1Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregator).to.be.equal(nativeTokenAmount);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.address);
        expect(balanceAggregatorToken1).to.be.equal(0)
        const ethBalanceReceiverContract = await ethers.provider.getBalance(receiverContract.address);
        expect(ethBalanceReceiverContract).to.be.equal(0)



        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount);

        await receiverContract.connect(user).approveTokens(token1.address, metaAggregatorTestManager.address, token1Amount)



        await receiverContract.connect(user).swap(metaAggregatorTestManager.address, token1.address, nativeToken, aggregator.address, swapData.data || "", token1Amount, nativeTokenAmount, receiverContract.address, false)



        const ethBalanceOfReceiverContract = await ethers.provider.getBalance(receiverContract.address);
        expect(Number(ethBalanceOfReceiverContract.sub(ethBalanceReceiverContract))).to.be.equal(nativeTokenAmount)
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address)
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
    })

    it("Swap token to token Enso Aggregator", async () => {
        const { token1, token2, ensoAggregator, metaAggregatorTestManager, user, receiver, ensoHelper } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(ensoHelper.address, token2Amount);

        const balanceUserToken1 = await token1.balanceOf(user.address);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const balanceUserToken2 = await token2.balanceOf(user.address);
        expect(balanceUserToken2).to.be.equal(0);
        const balanceReceiverToken1 = await token1.balanceOf(receiver.address);
        expect(balanceReceiverToken1).to.be.equal(0)


        const swapData = await ensoAggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount, receiver.address);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)


        await metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, ensoAggregator.address, swapData.data || "", token1Amount, token2Amount, user.address, true)

        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userToken1Balance = await token1.balanceOf(user.address);
        expect(userToken1Balance).to.be.equal(0);
        const receiverToken1Balance = await token1.balanceOf(receiver.address);
        expect(receiverToken1Balance).to.be.equal(token1Amount);
        const ensoHelperToken2Balance = await token2.balanceOf(ensoHelper.address);
        expect(ensoHelperToken2Balance).to.be.equal(0);


    })
    it("Swap ETh to token Enso Aggregator", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, receiver, ensoHelper } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const ethBalanceOfReceiver = await ethers.provider.getBalance(receiver.address);

        const swapData = await ensoAggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount, receiver.address);


        const tnx = await metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, ensoAggregator.address, swapData.data || "", nativeTokenAmount, token2Amount, user.address, true, { value: nativeTokenAmount })


        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }


        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const ethBalanceOfReceiverAfterSwap = await ethers.provider.getBalance(receiver.address);
        expect(ethBalanceOfReceiverAfterSwap.sub(ethBalanceOfReceiver)).to.be.equal(nativeTokenAmount);
    })


    it("Swap token to ETH Enso Aggregator", async () => {
        const { token1, ensoAggregator, metaAggregatorTestManager, nativeToken, executor, user, receiver, ensoHelper } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        executor.sendTransaction({
            to: ensoHelper.address,
            value: nativeTokenAmount
        });

        await token1.mint(user.address, token1Amount);

        const balanceUserToken1 = await token1.balanceOf(user.address);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const ethBalanceOfEnsoHelper = await ethers.provider.getBalance(ensoHelper.address);
        expect(ethBalanceOfEnsoHelper).to.be.equal(nativeTokenAmount);
        const balanceEnsoHelperToken1 = await token1.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken1).to.be.equal(0)
        const ethBalanceUser = await ethers.provider.getBalance(user.address);

        const swapData = await ensoAggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount, receiver.address);

        let tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)

        let tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);
        let approveTnxGasCost;

        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            approveTnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0);
        }

        tnx = await metaAggregatorTestManager.connect(user).swap(token1.address, nativeToken, ensoAggregator.address, swapData.data || "", token1Amount, nativeTokenAmount, user.address, true)


        tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUserAfterSwap.toString()).minus(BigNumber(ethBalanceUser.toString())).plus(tnxGasCost).plus(BigNumber(approveTnxGasCost || 0)).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const receiverToken1Balance = await token1.balanceOf(receiver.address)
        expect(receiverToken1Balance).to.be.equal(token1Amount);
    })
});

describe("Coverage test", async () => {
    it("should fail if the user has not approved the manager to swap their tokens", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);


        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, aggregator.address, swapData.data || "" || "", token1Amount, token2Amount, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestManager, "TransferFromFailed")
    })
    it("should fail if the user doesn't have token to swap", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();
        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, aggregator.address, swapData.data || "" || "", token1Amount, token2Amount, user.address, false)).to.revertedWithCustomError(metaAggregatorTestManager, "TransferFromFailed")
    })
    it("should fail if for re-entrancy call to swap manager contract", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, nonReentrantTest, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);


        const reEntrantData = await nonReentrantTest.populateTransaction.receiveCall(metaAggregatorTestManager.address, token1.address, token2.address, aggregator.address, swapData.data || "" || "", token1Amount, token2Amount, user.address, false);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, nonReentrantTest.address, reEntrantData.data || " ", token1Amount, token2Amount, user.address, false)).to.revertedWithCustomError(metaAggregatorTestSwapContract, "ReentrancyGuardReentrantCall")
    })
    it("should fail if ETH to token was tried to swap on manager contract", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, nativeToken } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(user).swap(nativeToken, token2.address, aggregator.address, swapData.data || "" || "", token1Amount, token2Amount, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestManager, "CannotSwapETH")
    })

    it("should fail when token fail swapping tokens using swapETH method", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, token1 } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(token1.address, token2.address, aggregator.address, swapData.data || "" || "", nativeTokenAmount, token2Amount, user.address, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "CannotSwapTokens")

    })
    it("should fail when the minAmountOut is zero", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, aggregator.address, swapData.data || "" || "", nativeTokenAmount, 0, user.address, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "MinAmountOutMustBeGreaterThanZero")
    })
    it("should fail when amount in is zero", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, aggregator.address, swapData.data || "" || "", 0, token2Amount, user.address, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "AmountInMustBeGreaterThanZero")
    })
    it("should fail when same token are tried to swap", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, nativeToken, aggregator.address, swapData.data || "" || "", nativeTokenAmount, token2Amount, user.address, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "TokenInAndTokenOutCannotBeSame")
    })
    it("should fail when tokens swapped are same swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token1.address, aggregator.address, swapData.data || "" || "", token1Amount, token2Amount, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "TokenInAndTokenOutCannotBeSame")
    })
    it("should fail when amount out is zero for swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, aggregator.address, swapData.data || "" || "", token1Amount, 0, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "MinAmountOutMustBeGreaterThanZero")
    })
    it("should fail when amount in is zero for swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, aggregator.address, swapData.data || "" || "", 0, token2Amount, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "AmountInMustBeGreaterThanZero")
    })
    it("should fail when incorrect ETH amount is sent in swapETh", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, aggregator.address, swapData.data || "", nativeTokenAmount, token2Amount, user.address, false, { value: 0 })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "IncorrectEtherAmountSent")
    })
    it("should fail when token amount swapped is not sufficient through swapETh method", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, 20);

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, aggregator.address, swapData.data || "", nativeTokenAmount, token2Amount, user.address, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientOutputBalance")
    })
    it("should fail when tokens swapped out amount is not enough through swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, 20);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, aggregator.address, swapData.data || "", token1Amount, token2Amount, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientTokenOutAmount")
    })

    it("should fail when ETH swapped out amount is not enough through swapERC20", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;



        await executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });

        await token1.mint(user.address, token1Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, 30);

        let tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait()

        await ethers.provider.getTransactionReceipt(tnx.hash);

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, nativeToken, aggregator.address, swapData.data || "", token1Amount, nativeTokenAmount, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientETHOutAmount")
    })

    it("should fail when re-entrancy attack if performed on swapERC20 method", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, metaAggregatorTestSwapContract, nonReentrantTest } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        await executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });

        await token1.mint(user.address, token1Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, 30);

        const reEntrantData = await nonReentrantTest.populateTransaction.receiverCallToken(metaAggregatorTestSwapContract.address, token1.address, nativeToken, aggregator.address, swapData.data || "" || "", token1Amount, nativeTokenAmount, user.address, false);

        await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, nativeToken, nonReentrantTest.address, reEntrantData.data || "", token1Amount, nativeTokenAmount, user.address, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "ReentrancyGuardReentrantCall")
    })
    it("should fail when re-entrancy attack is made on swapETH method", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, receiver, ensoHelper, nonReentrantTest } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.address, token2Amount);


        const swapData = await ensoAggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount, receiver.address);


        const reEntrantData = await nonReentrantTest.populateTransaction.receiverCallETH(metaAggregatorTestSwapContract.address, token2.address, nativeToken, metaAggregatorTestSwapContract.address, swapData.data || "" || "", nativeTokenAmount, token2Amount, user.address, false);



        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, nonReentrantTest.address, reEntrantData.data || "", nativeTokenAmount, token2Amount, user.address, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "ReentrancyGuardReentrantCall")
    })
    it("should fail when call to enso fails", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, ensoHelper } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.address, token2Amount);

        const swapData = await ensoAggregator.populateTransaction.swapFail();


        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, ensoAggregator.address, swapData.data || "" || "", nativeTokenAmount, token2Amount, user.address, true, { value: nativeTokenAmount })).to.be.reverted
    })

    it("should fail if the receiver contract reverts on receive Eth", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, receiverRevert } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;



        await executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });


        await token1.mint(receiverContract.address, token1Amount);



        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount);

        await receiverContract.connect(user).approveTokens(token1.address, metaAggregatorTestManager.address, token1Amount)

        await expect(receiverContract.connect(user).swap(metaAggregatorTestManager.address, token1.address, nativeToken, aggregator.address, swapData.data || "" || "", token1Amount, nativeTokenAmount, receiverRevert.address, false)).to.be.reverted
    })
    it("should fail when receiver is zero address token to token swap", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract, zeroAddress } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(user).swap(token1.address, token2.address, aggregator.address, swapData.data || "" || "", token1Amount, token2Amount, zeroAddress, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidReceiver")
    })
    it("should fail when receiver address is zero ETH to token swap", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, zeroAddress } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(nativeToken, token2.address, aggregator.address, swapData.data || "" || "", nativeTokenAmount, token2Amount, zeroAddress, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidReceiver")
    })

    it("should revert when deploying manager with invalid swap contract address", async () => {
        const { zeroAddress } = await loadFixture(setupTest);
        const MetaAggregatorManager = await ethers.getContractFactory("MetaAggregatorManager");
        await expect(MetaAggregatorManager.deploy(zeroAddress)).to.be.reverted;

    })
    it("should fail when deploying swap contract with invalid enso aggregator contract", async () => {
        const { zeroAddress } = await loadFixture(setupTest);

        const MetaAggregatorTestSwapContract = await ethers.getContractFactory("MetaAggregatorSwapContract");

        await expect(MetaAggregatorTestSwapContract.deploy(zeroAddress)).to.be.reverted;

    })
})
