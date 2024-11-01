import { expect } from "chai";
import { ethers } from "hardhat";
import { setupTest } from "./fixture";
import BigNumber from "bignumber.js";

describe("Swap test", function () {
    it("Swap tokens to tokens", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);


        const balanceUserToken1 = await token1.balanceOf(user);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.target);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceUserToken2 = await token2.balanceOf(user);
        expect(balanceUserToken2).to.be.equal(0);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.target);
        expect(balanceAggregatorToken1).to.be.equal(0)

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, aggregator.target, swapData.data, token1Amount, token2Amount, user, false)


        const userToken2Balance = await token2.balanceOf(user)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userToken1Balance = await token1.balanceOf(user);
        expect(userToken1Balance).to.be.equal(0);
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.target);
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
        const aggregatorToken2Balance = await token2.balanceOf(aggregator.target);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap ETH to token", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.target);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.target);
        expect(ethBalanceOfAggregator).to.be.equal(0);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount);

        const tnx = await metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, aggregator.target, swapData.data, nativeTokenAmount, token2Amount, user, false, { value: nativeTokenAmount })

        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.gasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.gasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }


        const userToken2Balance = await token2.balanceOf(user)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const ethBalanceOfAggregatorAfterSwap = await ethers.provider.getBalance(aggregator.target);
        expect(ethBalanceOfAggregatorAfterSwap - ethBalanceOfAggregator).to.be.equal(nativeTokenAmount);

    })


    it("Swap token to ETH", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, nativeToken, executor, user } = await setupTest();


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        const executorWallet = await ethers.provider.getSigner(executor)

        const tx = await executorWallet.sendTransaction({
            to: aggregator.target,
            value: nativeTokenAmount
        });


        await token1.mint(user, token1Amount);

        const balanceUserToken1 = await token1.balanceOf(user);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.target);
        expect(ethBalanceOfAggregator).to.be.equal(nativeTokenAmount);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.target);
        expect(balanceAggregatorToken1).to.be.equal(0)
        const ethBalanceUser = await ethers.provider.getBalance(user);



        const swapData = await aggregator.swap.populateTransaction(token1.target, nativeToken, token1Amount, nativeTokenAmount);

        let tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait()

        let tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);
        let approveTnxGasCost;
        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.gasPrice) {

            approveTnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.gasPrice.toString()).toFixed(0);
        }


        tnx = await metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, nativeToken, aggregator.target, swapData.data, token1Amount, nativeTokenAmount, user, false)
        await tnx.wait();

        tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.gasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.gasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user);
            expect(Number(BigNumber(ethBalanceUserAfterSwap.toString()).minus(BigNumber(ethBalanceUser.toString())).plus(tnxGasCost).plus(BigNumber(approveTnxGasCost || 0)).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const aggregatorToken1Balance = await token1.balanceOf(aggregator.target)
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
    })

    it("Swap token to ETH receiver is contract", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract } = await setupTest();


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        const executorWallet = await ethers.provider.getSigner(executor)

        await executorWallet.sendTransaction({
            to: aggregator.target,
            value: nativeTokenAmount
        });


        await token1.mint(receiverContract.target, token1Amount);

        const balanceReceiverContractToken1 = await token1.balanceOf(receiverContract.target);
        expect(balanceReceiverContractToken1).to.be.equal(token1Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.target);
        expect(ethBalanceOfAggregator).to.be.equal(nativeTokenAmount);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.target);
        expect(balanceAggregatorToken1).to.be.equal(0)
        const ethBalanceReceiverContract = await ethers.provider.getBalance(receiverContract.target);
        expect(ethBalanceReceiverContract).to.be.equal(0)



        const swapData = await aggregator.swap.populateTransaction(token1.target, nativeToken, token1Amount, nativeTokenAmount);

        await receiverContract.connect(await ethers.getSigner(user)).approveTokens(token1.target, metaAggregatorTestManager.target, token1Amount)



        await receiverContract.connect(await ethers.provider.getSigner(user)).swap(metaAggregatorTestManager.target, token1.target, nativeToken, aggregator.target, swapData.data, token1Amount, nativeTokenAmount, receiverContract.target, false)



        const ethBalanceOfReceiverContract = await ethers.provider.getBalance(receiverContract.target);
        expect(ethBalanceOfReceiverContract - ethBalanceReceiverContract).to.be.equal(nativeTokenAmount)
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.target)
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
    })

    it("Swap token to token Enso Aggregator", async () => {
        const { token1, token2, ensoAggregator, metaAggregatorTestManager, user, receiver, ensoHelper } = await setupTest();


        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(ensoHelper.target, token2Amount);

        const balanceUserToken1 = await token1.balanceOf(user);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.target);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const balanceUserToken2 = await token2.balanceOf(user);
        expect(balanceUserToken2).to.be.equal(0);
        const balanceReceiverToken1 = await token1.balanceOf(receiver);
        expect(balanceReceiverToken1).to.be.equal(0)


        const swapData = await ensoAggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount, receiver);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)


        await metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, ensoAggregator.target, swapData.data, token1Amount, token2Amount, user, true)

        const userToken2Balance = await token2.balanceOf(user)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userToken1Balance = await token1.balanceOf(user);
        expect(userToken1Balance).to.be.equal(0);
        const receiverToken1Balance = await token1.balanceOf(receiver);
        expect(receiverToken1Balance).to.be.equal(token1Amount);
        const ensoHelperToken2Balance = await token2.balanceOf(ensoHelper.target);
        expect(ensoHelperToken2Balance).to.be.equal(0);


    })
    it("Swap ETh to token Enso Aggregator", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, receiver, ensoHelper } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.target, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.target);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const ethBalanceOfReceiver = await ethers.provider.getBalance(receiver);

        const swapData = await ensoAggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount, receiver);


        const tnx = await metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, ensoAggregator.target, swapData.data, nativeTokenAmount, token2Amount, user, true, { value: nativeTokenAmount })


        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.gasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.gasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }


        const userToken2Balance = await token2.balanceOf(user)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const ethBalanceOfReceiverAfterSwap = await ethers.provider.getBalance(receiver);
        expect(ethBalanceOfReceiverAfterSwap - ethBalanceOfReceiver).to.be.equal(nativeTokenAmount);
    })


    it("Swap token to ETH Enso Aggregator", async () => {
        const { token1, ensoAggregator, metaAggregatorTestManager, nativeToken, executor, user, receiver, ensoHelper } = await setupTest();


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        const executorWallet = await ethers.provider.getSigner(executor)

        const tx = await executorWallet.sendTransaction({
            to: ensoHelper.target,
            value: nativeTokenAmount
        });

        await token1.mint(user, token1Amount);

        const balanceUserToken1 = await token1.balanceOf(user);
        expect(balanceUserToken1).to.be.equal(token1Amount);
        const ethBalanceOfEnsoHelper = await ethers.provider.getBalance(ensoHelper.target);
        expect(ethBalanceOfEnsoHelper).to.be.equal(nativeTokenAmount);
        const balanceEnsoHelperToken1 = await token1.balanceOf(ensoHelper.target);
        expect(balanceEnsoHelperToken1).to.be.equal(0)
        const ethBalanceUser = await ethers.provider.getBalance(user);

        const swapData = await ensoAggregator.swap.populateTransaction(token1.target, nativeToken, token1Amount, nativeTokenAmount, receiver);

        let tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)

        let tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);
        let approveTnxGasCost;

        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.gasPrice) {
            approveTnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.gasPrice.toString()).toFixed(0);
        }

        tnx = await metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, nativeToken, ensoAggregator.target, swapData.data, token1Amount, nativeTokenAmount, user, true)


        tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.gasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.gasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user);
            expect(Number(BigNumber(ethBalanceUserAfterSwap.toString()).minus(BigNumber(ethBalanceUser.toString())).plus(tnxGasCost).plus(BigNumber(approveTnxGasCost || 0)).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const receiverToken1Balance = await token1.balanceOf(receiver)
        expect(receiverToken1Balance).to.be.equal(token1Amount);
    })
});

describe(" test", async () => {
    it("should fail if the user has not approved the manager to swap their tokens", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, aggregator.target, swapData.data, token1Amount, token2Amount, user, false)).to.revertedWithCustomError(metaAggregatorTestManager, "TransferFromFailed")
    })
    it("should fail if the user doesn't have token to swap", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();
        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, aggregator.target, swapData.data, token1Amount, token2Amount, user, false)).to.revertedWithCustomError(metaAggregatorTestManager, "TransferFromFailed")
    })
    it("should fail if for re-entrancy call to swap manager contract", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, nonReentrantTest, metaAggregatorTestSwapContract } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);


        const reEntrantData = await nonReentrantTest.receiveCall.populateTransaction(metaAggregatorTestManager.target, token1.target, token2.target, aggregator.target, swapData.data, token1Amount, token2Amount, user, false);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, nonReentrantTest.target, reEntrantData.data, token1Amount, token2Amount, user, false)).to.revertedWithCustomError(metaAggregatorTestSwapContract, "ReentrancyGuardReentrantCall")
    })
    it("should fail if ETH to token was tried to swap on manager contract", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, nativeToken } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(nativeToken, token2.target, aggregator.target, swapData.data, token1Amount, token2Amount, user, false)).to.be.revertedWithCustomError(metaAggregatorTestManager, "CannotSwapETH")
    })

    it("should fail when token fail swapping tokens using swapETH method", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, token1 } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(token1.target, token2.target, aggregator.target, swapData.data, nativeTokenAmount, token2Amount, user, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "CannotSwapTokens")

    })
    it("should fail when the minAmountOut is zero", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, aggregator.target, swapData.data, nativeTokenAmount, 0, user, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "MinAmountOutMustBeGreaterThanZero")
    })
    it("should fail when amount in is zero", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, aggregator.target, swapData.data, 0, token2Amount, user, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "AmountInMustBeGreaterThanZero")
    })
    it("should fail when same token are tried to swap", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, nativeToken, aggregator.target, swapData.data, nativeTokenAmount, token2Amount, user, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "TokenInAndTokenOutCannotBeSame")
    })
    it("should fail when tokens swapped are same swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token1.target, aggregator.target, swapData.data, token1Amount, token2Amount, user, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract,"TokenInAndTokenOutCannotBeSame")
    })
    it("should fail when amount out is zero for swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, aggregator.target, swapData.data, token1Amount, 0, user, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract,"MinAmountOutMustBeGreaterThanZero")
    })
    it("should fail when amount in is zero for swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, aggregator.target, swapData.data, 0, token2Amount, user, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract,"AmountInMustBeGreaterThanZero")
    })
    it("should fail when incorrect ETH amount is sent in swapETh", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount);

        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, aggregator.target, swapData.data, nativeTokenAmount, token2Amount, user, false, { value: 0 })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "IncorrectEtherAmountSent")
    })
    it("should fail when token amount swapped is not sufficient through swapETh method", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, 20);

        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, aggregator.target, swapData.data, nativeTokenAmount, token2Amount, user, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientOutputBalance")
    })
    it("should fail when tokens swapped out amount is not enough through swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, 20);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, aggregator.target, swapData.data, token1Amount, token2Amount, user, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientTokenOutAmount")
    })

    it("should fail when ETH swapped out amount is not enough through swapERC20", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, metaAggregatorTestSwapContract } = await setupTest();


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        const executorWallet = await ethers.provider.getSigner(executor)

        await executorWallet.sendTransaction({
            to: aggregator.target,
            value: nativeTokenAmount
        });

        await token1.mint(user, token1Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, nativeToken, token1Amount, 30);

        let tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait()

        await ethers.provider.getTransactionReceipt(tnx.hash);

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, nativeToken, aggregator.target, swapData.data, token1Amount, nativeTokenAmount, user, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientETHOutAmount")
    })

    it("should fail when re-entrancy attack if performed on swapERC20 method", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, metaAggregatorTestSwapContract, nonReentrantTest } = await setupTest();


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        const executorWallet = await ethers.provider.getSigner(executor)

        await executorWallet.sendTransaction({
            to: aggregator.target,
            value: nativeTokenAmount
        });

        await token1.mint(user, token1Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, nativeToken, token1Amount, 30);

        const reEntrantData = await nonReentrantTest.receiverCallToken.populateTransaction(metaAggregatorTestSwapContract.target, token1.target, nativeToken, aggregator.target, swapData.data, token1Amount, nativeTokenAmount, user, false);

        await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, nativeToken, nonReentrantTest.target, reEntrantData.data, token1Amount, nativeTokenAmount, user, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "ReentrancyGuardReentrantCall")
    })
    it("should fail when re-entrancy attack is made on swapETH method", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, receiver, ensoHelper, nonReentrantTest } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.target, token2Amount);


        const swapData = await ensoAggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount, receiver);


        const reEntrantData = await nonReentrantTest.receiverCallETH.populateTransaction(metaAggregatorTestSwapContract.target, token2.target, nativeToken, metaAggregatorTestSwapContract.target, swapData.data, nativeTokenAmount, token2Amount, user, false);



        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, nonReentrantTest.target, reEntrantData.data, nativeTokenAmount, token2Amount, user, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "ReentrancyGuardReentrantCall")
    })
    it("should fail when call to enso fails", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, ensoHelper } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.target, token2Amount);

        const swapData = await ensoAggregator.swapFail.populateTransaction();


        await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, ensoAggregator.target, swapData.data, nativeTokenAmount, token2Amount, user, true, { value: nativeTokenAmount })).to.be.reverted
    })

    it("should fail if the receiver contract reverts on receive Eth", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, receiverRevert } = await setupTest();


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        const executorWallet = await ethers.provider.getSigner(executor)

        await executorWallet.sendTransaction({
            to: aggregator.target,
            value: nativeTokenAmount
        });


        await token1.mint(receiverContract.target, token1Amount);



        const swapData = await aggregator.swap.populateTransaction(token1.target, nativeToken, token1Amount, nativeTokenAmount);

        await receiverContract.connect(await ethers.getSigner(user)).approveTokens(token1.target, metaAggregatorTestManager.target, token1Amount)

        await expect(receiverContract.connect(await ethers.provider.getSigner(user)).swap(metaAggregatorTestManager.target, token1.target, nativeToken, aggregator.target, swapData.data, token1Amount, nativeTokenAmount, receiverRevert.target, false)).to.be.reverted
    })
    it("should fail when receiver is zero address token to token swap", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract, zeroAddress } = await setupTest();

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user, token1Amount);
        await token2.mint(aggregator.target, token2Amount);

        const swapData = await aggregator.swap.populateTransaction(token1.target, token2.target, token1Amount, token2Amount);

        const tnx = await token1.connect(await ethers.getSigner(user)).approve(metaAggregatorTestManager.target, token1Amount)
        await tnx.wait();

        await expect(metaAggregatorTestManager.connect(await ethers.provider.getSigner(user)).swap(token1.target, token2.target, aggregator.target, swapData.data, token1Amount, token2Amount, zeroAddress, false)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidReceiver")
    })
    it("should fail when receiver address is zero ETH to token swap", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, zeroAddress } = await setupTest();


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.target, token2Amount);


        const swapData = await aggregator.swap.populateTransaction(nativeToken, token2.target, nativeTokenAmount, token2Amount);

       await expect(metaAggregatorTestSwapContract.connect(await ethers.provider.getSigner(user)).swapETH(nativeToken, token2.target, aggregator.target, swapData.data, nativeTokenAmount, token2Amount, zeroAddress, false, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidReceiver")
    })

    it("should revert when deploying manager with invalid swap contract address", async () => {
        const {  deploy, deployer, zeroAddress } = await setupTest();

        await expect(deploy("MetaAggregatorManager", {
            from: deployer,
            contract: "MetaAggregatorManager",
            args: [zeroAddress],
            log: true,
        })).to.be.reverted;
       
    })
    it("should fail when deploying swap contract with invalid enso aggregator contract", async () => {
        const {  deploy, deployer, zeroAddress } = await setupTest();

        await expect(deploy("MetaAggregatorSwapContract", {
            from: deployer,
            contract: "MetaAggregatorSwapContract",
            args: [zeroAddress],
            log: true,
        })).to.be.reverted;
       
    })
})
