import BigNumber from "bignumber.js";
import { expect } from "chai";
import { ethers } from "hardhat";
import { setupTest } from "./fixture";
import {
    loadFixture,
} from "@nomicfoundation/hardhat-network-helpers";
import { calculateFee, divideFee } from "./utils";

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

        const swapETHParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };

        await metaAggregatorTestManager.connect(user).swap(swapETHParams)


        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userToken1Balance = await token1.balanceOf(user.address);
        expect(userToken1Balance).to.be.equal(0);
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address);
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
        const aggregatorToken2Balance = await token2.balanceOf(aggregator.address);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap tokens to tokens send fee to both the receiver", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, feeReceiver1, feeReceiver2 } = await loadFixture(setupTest);
        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const token1Amount = "594675716556465465156456456";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(token1Amount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)



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
        expect(fee).to.be.equal(new BigNumber(feeReceiver1Amount).plus(new BigNumber(feeReceiver2Amount)).toFixed(0))
        const feeTransferData1 = await token1.populateTransaction.transfer(feeReceiver1.address, feeReceiver1Amount)
        const feeTransferData2 = await token1.populateTransaction.transfer(feeReceiver2.address, feeReceiver2Amount)

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, amountAfterFee, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapETHParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [token1.address, token1.address],
            calldataArray: [feeTransferData1.data || "", feeTransferData2.data || ""]
        };

        await metaAggregatorTestManager.connect(user).swap(swapETHParams)


        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userToken1Balance = await token1.balanceOf(user.address);
        expect(userToken1Balance).to.be.equal(0);
        const feeReceiver1Token1Balance = await token1.balanceOf(feeReceiver1.address);
        expect(feeReceiver1Token1Balance).to.be.equal(feeReceiver1Amount);
        const feeReceiver2Token1Balance = await token1.balanceOf(feeReceiver2.address);
        expect(feeReceiver2Token1Balance).to.be.equal(feeReceiver2Amount);
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address);
        expect(aggregatorToken1Balance).to.be.equal(amountAfterFee);

        const aggregatorToken2Balance = await token2.balanceOf(aggregator.address);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap usdt to tokens", async () => {
        const { usdt, token2, aggregator, metaAggregatorTestManager, user } = await loadFixture(setupTest);

        const usdtAmount = 100000000;
        const token2Amount = 100000000;

        await usdt.mint(user.address, usdtAmount);
        await token2.mint(aggregator.address, token2Amount);


        const balanceUserUSDT = await usdt.balanceOf(user.address);
        expect(balanceUserUSDT).to.be.equal(usdtAmount);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceUserToken2 = await token2.balanceOf(user.address);
        expect(balanceUserToken2).to.be.equal(0);
        const balanceAggregatorUSDT = await usdt.balanceOf(aggregator.address);
        expect(balanceAggregatorUSDT).to.be.equal(0)

        const swapData = await aggregator.populateTransaction.swap(usdt.address, token2.address, usdtAmount, token2Amount);

        const tnx = await usdt.connect(user).approve(metaAggregatorTestManager.address, usdtAmount)
        await tnx.wait();

        const swapUSDTParams = {
            tokenIn: usdt.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: usdtAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };

        await metaAggregatorTestManager.connect(user).swap(swapUSDTParams)


        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userUSDTBalance = await usdt.balanceOf(user.address);
        expect(userUSDTBalance).to.be.equal(0);
        const aggregatorUSDTBalance = await usdt.balanceOf(aggregator.address);
        expect(aggregatorUSDTBalance).to.be.equal(usdtAmount);
        const aggregatorToken2Balance = await token2.balanceOf(aggregator.address);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap tokens to tokens through delegate call", async () => {
        const { token1, token2, aggregator, user, receiverContract, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const balanceOfReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractToken1).to.be.equal(token1Amount);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceOfReceiverContractToken2 = await token2.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractToken2).to.be.equal(0);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.address);
        expect(balanceAggregatorToken1).to.be.equal(0)

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);


        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };


        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")


        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(token2Amount);
        const receiverContractToken1Balance = await token1.balanceOf(receiverContract.address);
        expect(receiverContractToken1Balance).to.be.equal(0);
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address);
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
        const aggregatorToken2Balance = await token2.balanceOf(aggregator.address);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap tokens to tokens through delegate call send fee to both the receiver", async () => {
        const { token1, token2, aggregator, user, receiverContract, metaAggregatorTestSwapContract, feeReceiver1, feeReceiver2 } = await loadFixture(setupTest);

        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const token1Amount = "594675716556465465156456456";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(token1Amount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const balanceOfReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractToken1).to.be.equal(token1Amount);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceOfReceiverContractToken2 = await token2.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractToken2).to.be.equal(0);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.address);
        expect(balanceAggregatorToken1).to.be.equal(0)
        expect(fee).to.be.equal(new BigNumber(feeReceiver1Amount).plus(new BigNumber(feeReceiver2Amount)).toFixed(0))

        const feeTransferData1 = await token1.populateTransaction.transfer(feeReceiver1.address, feeReceiver1Amount)
        const feeTransferData2 = await token1.populateTransaction.transfer(feeReceiver2.address, feeReceiver2Amount)


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, amountAfterFee, token2Amount);


        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [token1.address, token1.address],
            calldataArray: [feeTransferData1.data || "", feeTransferData2.data || ""]
        };


        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")

        const feeReceiver1Token1Balance = await token1.balanceOf(feeReceiver1.address);
        expect(feeReceiver1Token1Balance).to.be.equal(feeReceiver1Amount);
        const feeReceiver2Token1Balance = await token1.balanceOf(feeReceiver2.address);
        expect(feeReceiver2Token1Balance).to.be.equal(feeReceiver2Amount);
        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(token2Amount);
        const receiverContractToken1Balance = await token1.balanceOf(receiverContract.address);
        expect(receiverContractToken1Balance).to.be.equal(0);
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address);
        expect(aggregatorToken1Balance).to.be.equal(amountAfterFee);
        const aggregatorToken2Balance = await token2.balanceOf(aggregator.address);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap usdt to tokens through delegate call", async () => {
        const { usdt, token2, aggregator, user, receiverContract, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const usdtAmount = 100000000;
        const token2Amount = 100000000;

        await usdt.mint(receiverContract.address, usdtAmount);
        await token2.mint(aggregator.address, token2Amount);


        const balanceOfReceiverContractUSDT = await usdt.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractUSDT).to.be.equal(usdtAmount);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceOfReceiverContractToken2 = await token2.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractToken2).to.be.equal(0);
        const balanceAggregatorUSDT = await usdt.balanceOf(aggregator.address);
        expect(balanceAggregatorUSDT).to.be.equal(0)

        const swapData = await aggregator.populateTransaction.swap(usdt.address, token2.address, usdtAmount, token2Amount);


        const swapUSDTParams = {
            tokenIn: usdt.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: usdtAmount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };




        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapUSDTParams)

        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")
        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);
        const gasCost = tnxReceipt?.cumulativeGasUsed ? BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0) : "0";


        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(token2Amount);
        const receiverContractUSDTBalance = await usdt.balanceOf(receiverContract.address);
        expect(receiverContractUSDTBalance).to.be.equal(0);
        const aggregatorUSDTBalance = await usdt.balanceOf(aggregator.address);
        expect(aggregatorUSDTBalance).to.be.equal(usdtAmount);
        const aggregatorToken2Balance = await token2.balanceOf(aggregator.address);
        expect(aggregatorToken2Balance).to.be.equal(0);
    })
    it("Swap tokens to tokens through delegate call different receiver", async () => {
        const { token1, token2, aggregator, user, receiverContract, metaAggregatorTestSwapContract, receiver } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const balanceOfReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractToken1).to.be.equal(token1Amount);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceReceiverToken2 = await token2.balanceOf(receiver.address);
        expect(balanceReceiverToken2).to.be.equal(0);
        const balanceOfReceiverContractToken2 = await token2.balanceOf(receiverContract.address);
        expect(balanceOfReceiverContractToken2).to.be.equal(0);
        const balanceAggregatorToken1 = await token1.balanceOf(aggregator.address);
        expect(balanceAggregatorToken1).to.be.equal(0)

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: receiver.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };


        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")


        const receiverToken2Balance = await token2.balanceOf(receiver.address)
        expect(receiverToken2Balance).to.be.equal(token2Amount);
        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(0);
        const receiverContractToken1Balance = await token1.balanceOf(receiverContract.address);
        expect(receiverContractToken1Balance).to.be.equal(0);
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

        const swapETHParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        };

        const tnx = await metaAggregatorTestSwapContract.connect(user).swapETH(swapETHParams, { value: nativeTokenAmount })

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
    it("Swap ETH to token and send fee to both the receiver", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, feeReceiver1, feeReceiver2 } = await loadFixture(setupTest);

        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const nativeTokenAmount = "59467571655646";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(nativeTokenAmount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)

        await token2.mint(aggregator.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);
        const feeReceiver1Balance = await ethers.provider.getBalance(feeReceiver1.address);
        const feeReceiver2Balance = await ethers.provider.getBalance(feeReceiver2.address);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregator).to.be.equal(0);

        expect(fee).to.be.equal(new BigNumber(feeReceiver1Amount).plus(new BigNumber(feeReceiver2Amount)).toFixed(0))

        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, amountAfterFee, token2Amount);

        const swapETHParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [feeReceiver1.address, feeReceiver2.address],
            values: [feeReceiver1Amount, feeReceiver2Amount]
        };

        const tnx = await metaAggregatorTestSwapContract.connect(user).swapETH(swapETHParams, { value: nativeTokenAmount })

        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0)).to.be.equal(nativeTokenAmount)
        }


        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const ethBalanceOfAggregatorAfterSwap = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregatorAfterSwap.sub(ethBalanceOfAggregator)).to.be.equal(amountAfterFee);
        const feeReceiver1BalanceAfterSwap = await ethers.provider.getBalance(feeReceiver1.address);
        expect(feeReceiver1BalanceAfterSwap.sub(feeReceiver1Balance)).to.be.equal(feeReceiver1Amount);
        const feeReceiver2BalanceAfterSwap = await ethers.provider.getBalance(feeReceiver2.address);
        expect(feeReceiver2BalanceAfterSwap.sub(feeReceiver2Balance)).to.be.equal(feeReceiver2Amount);
    })
    it("Swap ETH to token through delegate call", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, receiverContract } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregator).to.be.equal(0);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapETHParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            values: []
        };

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapETHParams)



        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })
        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(token2Amount);
        const ethBalanceOfAggregatorAfterSwap = await ethers.provider.getBalance(aggregator.address);
        expect(Number(ethBalanceOfAggregatorAfterSwap.sub(ethBalanceOfAggregator))).to.be.equal(nativeTokenAmount);
    })

    it("Swap ETH to token through delegate call send fee to both the receiver", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, receiverContract, feeReceiver1, feeReceiver2 } = await loadFixture(setupTest);

        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const nativeTokenAmount = "59467571655646";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(nativeTokenAmount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)
        await token2.mint(aggregator.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        const feeReceiver1Balance = await ethers.provider.getBalance(feeReceiver1.address);
        const feeReceiver2Balance = await ethers.provider.getBalance(feeReceiver2.address);

        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregator).to.be.equal(0);

        expect(fee).to.be.equal(new BigNumber(feeReceiver1Amount).plus(new BigNumber(feeReceiver2Amount)).toFixed(0))


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, amountAfterFee, token2Amount);

        const swapETHParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [feeReceiver1.address, feeReceiver2.address],
            values: [feeReceiver1Amount, feeReceiver2Amount]
        };

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapETHParams)



        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })
        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0)).to.be.equal(nativeTokenAmount)
        }



        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(token2Amount);
        const ethBalanceOfAggregatorAfterSwap = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregatorAfterSwap.sub(ethBalanceOfAggregator)).to.be.equal(amountAfterFee);
        const feeReceiver1BalanceAfterSwap = await ethers.provider.getBalance(feeReceiver1.address);
        expect(feeReceiver1BalanceAfterSwap.sub(feeReceiver1Balance)).to.be.equal(feeReceiver1Amount);
        const feeReceiver2BalanceAfterSwap = await ethers.provider.getBalance(feeReceiver2.address);
        expect((feeReceiver2BalanceAfterSwap.sub(feeReceiver2Balance))).to.be.equal(feeReceiver2Amount);
    })
    it("Swap ETH to token through delegate call different receiver", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, receiverContract, receiver } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;




        await token2.mint(aggregator.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);
        const balanceAggregatorToken2 = await token2.balanceOf(aggregator.address);
        expect(balanceAggregatorToken2).to.be.equal(token2Amount);
        const balanceReceiverToken2 = await token2.balanceOf(receiver.address);
        expect(balanceReceiverToken2).to.be.equal(0);
        const ethBalanceOfAggregator = await ethers.provider.getBalance(aggregator.address);
        expect(ethBalanceOfAggregator).to.be.equal(0);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapETHParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: receiver.address,
            isDelegate: false,
            targets: [],
            values: []
        };

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapETHParams)



        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })
        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(0);
        const receiverToken2Balance = await token2.balanceOf(receiver.address)
        expect(receiverToken2Balance).to.be.equal(token2Amount);
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

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };


        tnx = await metaAggregatorTestManager.connect(user).swap(swapToken1Params)
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
    it("Swap token to ETH through delegate call", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, metaAggregatorTestSwapContract } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;



        const tx = await executor.sendTransaction({
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

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")
        await tnx.wait();

        const ethBalanceReceiverContractAfterSwap = await ethers.provider.getBalance(receiverContract.address);
        expect(ethBalanceReceiverContractAfterSwap).to.be.equal(nativeTokenAmount)
        const aggregatorToken1Balance = await token1.balanceOf(aggregator.address)
        expect(aggregatorToken1Balance).to.be.equal(token1Amount);
    })
    it("Swap token to ETH through delegate call different receiver", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, metaAggregatorTestSwapContract, receiver } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;



        const tx = await executor.sendTransaction({
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
        const ethBalanceReceiver = await ethers.provider.getBalance(receiver.address);


        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount);

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: receiver.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")
        await tnx.wait();

        const ethBalanceReceiverContractAfterSwap = await ethers.provider.getBalance(receiverContract.address);
        expect(ethBalanceReceiverContractAfterSwap).to.be.equal(0)
        const ethBalanceReceiverAfterSwap = await ethers.provider.getBalance(receiver.address);
        expect(Number((
            (BigNumber(ethBalanceReceiverAfterSwap.toString())
            ).minus(BigNumber(ethBalanceReceiver.toString())).toFixed(0)))).to.be.equal(nativeTokenAmount)
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


        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        };

        await receiverContract.connect(user).swap(metaAggregatorTestManager.address, swapToken1Params)



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

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: true,
            targets: [],
            calldataArray: []
        }

        await metaAggregatorTestManager.connect(user).swap(swapToken1Params)

        const userToken2Balance = await token2.balanceOf(user.address)
        expect(userToken2Balance).to.be.equal(token2Amount);
        const userToken1Balance = await token1.balanceOf(user.address);
        expect(userToken1Balance).to.be.equal(0);
        const receiverToken1Balance = await token1.balanceOf(receiver.address);
        expect(receiverToken1Balance).to.be.equal(token1Amount);
        const ensoHelperToken2Balance = await token2.balanceOf(ensoHelper.address);
        expect(ensoHelperToken2Balance).to.be.equal(0);
    })
    it("Swap token to token Enso Aggregator through delegate call", async () => {
        const { token1, token2, ensoAggregator, metaAggregatorTestManager, user, receiverContract, metaAggregatorTestSwapContract, ensoHelper } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(ensoHelper.address, token2Amount);

        const balanceReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceReceiverContractToken1).to.be.equal(token1Amount);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const balanceUserToken2 = await token2.balanceOf(user.address);
        expect(balanceUserToken2).to.be.equal(0);
        const balanceEnsoHelperToken1 = await token1.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken1).to.be.equal(0)


        const swapData = await ensoAggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount, ensoHelper.address);

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: true,
            targets: [],
            calldataArray: []
        }
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")


        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(token2Amount);
        const receiverContractToken1Balance = await token1.balanceOf(receiverContract.address);
        expect(receiverContractToken1Balance).to.be.equal(0);
        const EnsoHelperToken1Balance = await token1.balanceOf(ensoHelper.address);
        expect(EnsoHelperToken1Balance).to.be.equal(token1Amount);
        const ensoHelperToken2Balance = await token2.balanceOf(ensoHelper.address);
        expect(ensoHelperToken2Balance).to.be.equal(0);
    })
    it("Swap token to token Enso Aggregator through delegate call different receiver", async () => {
        const { token1, token2, ensoAggregator, metaAggregatorTestManager, user, receiverContract, metaAggregatorTestSwapContract, ensoHelper, receiver } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(ensoHelper.address, token2Amount);

        const balanceReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceReceiverContractToken1).to.be.equal(token1Amount);
        const balanceReceiverToken1 = await token1.balanceOf(receiver.address);
        expect(balanceReceiverToken1).to.be.equal(0);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const balanceUserToken2 = await token2.balanceOf(user.address);
        expect(balanceUserToken2).to.be.equal(0);
        const balanceEnsoHelperToken1 = await token1.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken1).to.be.equal(0)


        const swapData = await ensoAggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount, ensoHelper.address);

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: receiver.address,
            isDelegate: true,
            targets: [],
            calldataArray: []
        }


        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")


        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(0);
        const receiverToken2Balance = await token2.balanceOf(receiver.address)
        expect(receiverToken2Balance).to.be.equal(token2Amount);
        const receiverContractToken1Balance = await token1.balanceOf(receiverContract.address);
        expect(receiverContractToken1Balance).to.be.equal(0);
        const EnsoHelperToken1Balance = await token1.balanceOf(ensoHelper.address);
        expect(EnsoHelperToken1Balance).to.be.equal(token1Amount);
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


        const swapNativeParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: true,
            targets: [],
            values: []
        }

        const tnx = await metaAggregatorTestSwapContract.connect(user).swapETH(swapNativeParams, { value: nativeTokenAmount })


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
    it("Swap ETH to token Enso Aggregator through delegate call", async () => {
        const { token2, ensoAggregator, nativeToken, user, receiverContract, metaAggregatorTestSwapContract, ensoHelper } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);

        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(0);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const ethBalanceOfEnsoHelper = await ethers.provider.getBalance(ensoHelper.address);
        expect(ethBalanceOfEnsoHelper).to.be.equal(0)

        const swapData = await ensoAggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount, ensoHelper.address);

        const swapNativeParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: true,
            targets: [],
            values: []
        }
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapNativeParams)

        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })
        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }


        const receiverContractToken2BalanceAfterSwap = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2BalanceAfterSwap).to.be.equal(token2Amount);
        const ethBalanceOfEnsoHelperAfterSwap = await ethers.provider.getBalance(ensoHelper.address);
        expect(ethBalanceOfEnsoHelperAfterSwap.sub(ethBalanceOfEnsoHelper)).to.be.equal(nativeTokenAmount);
    })
    it("Swap ETh to token Enso Aggregator through delegate call different receiver", async () => {
        const { token2, ensoAggregator, nativeToken, user, receiverContract, metaAggregatorTestSwapContract, ensoHelper, receiver } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.address, token2Amount);

        const ethBalanceUser = await ethers.provider.getBalance(user.address);

        const receiverContractToken2Balance = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2Balance).to.be.equal(0);
        const receiverToken2Balance = await token2.balanceOf(receiver.address)
        expect(receiverToken2Balance).to.be.equal(0);
        const balanceEnsoHelperToken2 = await token2.balanceOf(ensoHelper.address);
        expect(balanceEnsoHelperToken2).to.be.equal(token2Amount);
        const ethBalanceOfEnsoHelper = await ethers.provider.getBalance(ensoHelper.address);
        expect(ethBalanceOfEnsoHelper).to.be.equal(0)

        const swapData = await ensoAggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount, ensoHelper.address);

        const swapNativeParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: receiver.address,
            isDelegate: true,
            targets: [],
            values: []
        }


        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapNativeParams)

        const tnx = await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })
        await tnx.wait();

        const tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUser.toString()).minus(BigNumber(ethBalanceUserAfterSwap.toString())).minus(tnxGasCost).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const receiverToken2BalanceAfterSwap = await token2.balanceOf(receiver.address)
        expect(receiverToken2BalanceAfterSwap).to.be.equal(token2Amount);
        const receiverContractToken2BalanceAfterSwap = await token2.balanceOf(receiverContract.address)
        expect(receiverContractToken2BalanceAfterSwap).to.be.equal(0);
        const ethBalanceOfEnsoHelperAfterSwap = await ethers.provider.getBalance(ensoHelper.address);
        expect(ethBalanceOfEnsoHelperAfterSwap.sub(ethBalanceOfEnsoHelper)).to.be.equal(nativeTokenAmount);
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

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: user.address,
            isDelegate: true,
            targets: [],
            calldataArray: []
        }
        tnx = await metaAggregatorTestManager.connect(user).swap(swapToken1Params)


        tnxReceipt = await ethers.provider.getTransactionReceipt(tnx.hash);


        if (tnxReceipt?.cumulativeGasUsed && tnxReceipt?.effectiveGasPrice) {
            const tnxGasCost = BigNumber(tnxReceipt?.cumulativeGasUsed.toString()).multipliedBy(tnxReceipt?.effectiveGasPrice.toString()).toFixed(0)
            const ethBalanceUserAfterSwap = await ethers.provider.getBalance(user.address);
            expect(Number(BigNumber(ethBalanceUserAfterSwap.toString()).minus(BigNumber(ethBalanceUser.toString())).plus(tnxGasCost).plus(BigNumber(approveTnxGasCost || 0)).toFixed(0))).to.be.equal(nativeTokenAmount)
        }

        const receiverToken1Balance = await token1.balanceOf(receiver.address)
        expect(receiverToken1Balance).to.be.equal(token1Amount);
    })
    it("Swap token to ETH Enso Aggregator through delegate call", async () => {
        const { token1, ensoAggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, metaAggregatorTestSwapContract, ensoHelper } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        executor.sendTransaction({
            to: ensoHelper.address,
            value: nativeTokenAmount
        });

        await token1.mint(receiverContract.address, token1Amount);

        const balanceReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceReceiverContractToken1).to.be.equal(token1Amount);
        const ethBalanceOfEnsoHelper = await ethers.provider.getBalance(ensoHelper.address);
        expect(ethBalanceOfEnsoHelper).to.be.equal(nativeTokenAmount);
        const ensoHelperToken1Balance = await token1.balanceOf(ensoHelper.address)
        expect(ensoHelperToken1Balance).to.be.equal(0);
        const ethBalanceReceiverContract = await ethers.provider.getBalance(receiverContract.address);
        expect(ethBalanceReceiverContract).to.be.equal(0)


        const swapData = await ensoAggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount, ensoHelper.address);


        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: receiverContract.address,
            isDelegate: true,
            targets: [],
            calldataArray: []
        }


        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")



        const ensoHelperToken1BalanceAfterSwap = await token1.balanceOf(ensoHelper.address)
        expect(ensoHelperToken1BalanceAfterSwap).to.be.equal(token1Amount);
        const ethBalanceReceiverContractAfterSwap = await ethers.provider.getBalance(receiverContract.address);
        expect(ethBalanceReceiverContractAfterSwap).to.be.equal(nativeTokenAmount)
    })
    it("Swap token to ETH Enso Aggregator through delegate call different receiver", async () => {
        const { token1, ensoAggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, metaAggregatorTestSwapContract, ensoHelper, receiver } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        executor.sendTransaction({
            to: ensoHelper.address,
            value: nativeTokenAmount
        });

        await token1.mint(receiverContract.address, token1Amount);

        const balanceReceiverContractToken1 = await token1.balanceOf(receiverContract.address);
        expect(balanceReceiverContractToken1).to.be.equal(token1Amount);
        const ethBalanceOfEnsoHelper = await ethers.provider.getBalance(ensoHelper.address);
        expect(ethBalanceOfEnsoHelper).to.be.equal(nativeTokenAmount);
        const ensoHelperToken1Balance = await token1.balanceOf(ensoHelper.address)
        expect(ensoHelperToken1Balance).to.be.equal(0);
        const ethBalanceReceiverContract = await ethers.provider.getBalance(receiverContract.address);
        expect(ethBalanceReceiverContract).to.be.equal(0)
        const ethBalanceReceiver = await ethers.provider.getBalance(receiver.address);


        const swapData = await ensoAggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount, ensoHelper.address);

        const swapToken1Params = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: receiver.address,
            isDelegate: true,
            targets: [],
            calldataArray: []
        }

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapToken1Params)

        await receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")



        const ensoHelperToken1BalanceAfterSwap = await token1.balanceOf(ensoHelper.address)
        expect(ensoHelperToken1BalanceAfterSwap).to.be.equal(token1Amount);
        const ethBalanceReceiverContractAfterSwap = await ethers.provider.getBalance(receiverContract.address);
        expect(ethBalanceReceiverContractAfterSwap).to.be.equal(0)
        const ethBalanceReceiverAfterSwap = await ethers.provider.getBalance(receiver.address);
        expect(Number((
            (BigNumber(ethBalanceReceiverAfterSwap.toString())
            ).minus(BigNumber(ethBalanceReceiver.toString())).toFixed(0)))).to.be.equal(nativeTokenAmount)
    })
});

describe("Coverage test", async () => {
    it("should revert if the user has not approved the manager to swap their tokens", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);


        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }


        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestManager, "TransferFromFailed")
    })
    it("should revert if the user doesn't have token to swap", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();
        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestManager, "TransferFromFailed")
    })
    it("should revert if for re-entrancy call to swap manager contract", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, nonReentrantTest, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);
        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        const reEntrantData = await nonReentrantTest.populateTransaction.receiveCall(metaAggregatorTestManager.address, swapParams);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)

        await tnx.wait();

        const swapParamsReentarnt = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: nonReentrantTest.address,
            swapData: reEntrantData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        await expect(metaAggregatorTestManager.connect(user).swap(swapParamsReentarnt)).to.revertedWith("ReentrancyGuard: reentrant call")
    })
    it("should revert if ETH to token was tried to swap on manager contract", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, nativeToken } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestManager, "CannotSwapETH")
    })
    it("should revert when swapping tokens using swapETH method", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, token1 } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "CannotSwapTokens")
    })
    it("should revert when the minAmountOut is zero", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: 0,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "MinAmountOutMustBeGreaterThanZero")
    })
    it("should revert when amount in is zero", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: 0,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "AmountInMustBeGreaterThanZero")
    })
    it("should revert when same token are tried to swap", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "TokenInAndTokenOutCannotBeSame")
    })
    it("should revert when tokens swapped are same swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token1.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "TokenInAndTokenOutCannotBeSame")
    })
    it("should revert when amount out is zero for swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: 0,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "MinAmountOutMustBeGreaterThanZero")
    })
    it("should revert when amount in is zero for swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: 0,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "AmountInMustBeGreaterThanZero")
    })
    it("should revert when incorrect ETH amount is sent in swapETh", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }
        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: 0 })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "IncorrectEtherAmountSent")
    })
    it("should revert when token amount swapped is not sufficient through swapETh method", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, 20);
        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }
        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientOutputBalance")
    })
    it("should revert when tokens swapped out amount is not enough through swapERC20", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, 20);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();
        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientTokenOutAmount")
    })
    it("should revert when ETH swapped out amount is not enough through swapERC20", async () => {
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
        const swapParams = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InsufficientETHOutAmount")
    })
    it("should revert when re-entrancy attack if performed on swapERC20 method", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, metaAggregatorTestSwapContract, nonReentrantTest } = await loadFixture(setupTest);


        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;


        await executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });

        await token1.mint(user.address, token1Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, 30);

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        const reEntrantData = await nonReentrantTest.populateTransaction.receiverCallToken(metaAggregatorTestSwapContract.address, swapParams);

        await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)


        const swapParamsReEntrant = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: nonReentrantTest.address,
            swapData: reEntrantData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        await expect(metaAggregatorTestManager.connect(user).swap(swapParamsReEntrant)).to.be.revertedWith("ReentrancyGuard: reentrant call")
    })
    it("should revert when re-entrancy attack is made on swapETH method", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, receiver, ensoHelper, nonReentrantTest } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.address, token2Amount);


        const swapData = await ensoAggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount, receiver.address);

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }


        const reEntrantData = await nonReentrantTest.populateTransaction.receiverCallETH(metaAggregatorTestSwapContract.address, swapParams);

        const swapParamsReEntrant = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: nonReentrantTest.address,
            swapData: reEntrantData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [],
            values: []
        }

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParamsReEntrant, { value: nativeTokenAmount })).to.be.revertedWith("ReentrancyGuard: reentrant call")
    })
    it("should revert when call to enso fails", async () => {
        const { token2, ensoAggregator, metaAggregatorTestSwapContract, nativeToken, user, ensoHelper } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(ensoHelper.address, token2Amount);

        const swapData = await ensoAggregator.populateTransaction.swapFail();

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: ensoAggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: true,
            targets: [],
            values: []
        }

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: nativeTokenAmount })).to.be.reverted
    })
    it("should revert if the receiver contract reverts on receive Eth", async () => {
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
        const swapParams = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: receiverRevert.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.reverted
    })
    it("should revert when receiver is zero address token to token swap", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, metaAggregatorTestSwapContract, zeroAddress } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: zeroAddress,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        await expect(metaAggregatorTestManager.connect(user).swap(swapParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidReceiver")
    })
    it("should revert when receiver address is zero ETH to token swap", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, zeroAddress } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);
        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: zeroAddress,
            isDelegate: false,
            targets: [],
            values: []
        }
        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidReceiver")
    })
    it("should revert when deploying manager with invalid swap contract address", async () => {
        const { zeroAddress } = await loadFixture(setupTest);
        const MetaAggregatorManager = await ethers.getContractFactory("MetaAggregatorManager");
        await expect(MetaAggregatorManager.deploy(zeroAddress)).to.be.reverted;
    })
    it("should revert when deploying swap contract with invalid enso aggregator contract", async () => {
        const { zeroAddress, usdt } = await loadFixture(setupTest);

        const MetaAggregatorTestSwapContract = await ethers.getContractFactory("MetaAggregatorSwapContract");

        await expect(MetaAggregatorTestSwapContract.deploy(zeroAddress, usdt.address)).to.be.reverted;

    })
    it("should revert when deploying swap contract with invalid usdt contract", async () => {
        const { ensoAggregator, zeroAddress } = await loadFixture(setupTest);

        const MetaAggregatorTestSwapContract = await ethers.getContractFactory("MetaAggregatorSwapContract");

        await expect(MetaAggregatorTestSwapContract.deploy(ensoAggregator.address, zeroAddress)).to.be.reverted;
    })

    it("should revert when native token is swapped through swap erc20 delegate function", async () => {
        const { token1, token2, aggregator, user, receiverContract, metaAggregatorTestSwapContract, nativeToken } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapParams)

        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")).to.be.reverted
    })
    it("should revert when tokens are swapped through swap eth delegate function", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, receiverContract } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);
        const swapParams = {
            tokenIn: token2.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            values: []
        }
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapParams)
        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })).to.be.reverted
    })
    it("should revert when eth value sent is smaller to amount in swap eth delegate call", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, receiverContract } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);

        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount * 2,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            values: []
        }

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapParams)



        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })).to.be.reverted
    })
    it("should revert when amount out is not equal to min amount out in swap eth delegate call", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, receiverContract } = await loadFixture(setupTest);


        const nativeTokenAmount = 100000000;
        const token2Amount = 100000000;

        await token2.mint(aggregator.address, token2Amount);

        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, nativeTokenAmount, token2Amount);
        const swapParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount * 2,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            values: []
        }

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapETH(swapParams)



        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ", { value: nativeTokenAmount })).to.be.reverted
    })
    it("should revert when token balance is not equal to amountIn for swap erc20 delegate function", async () => {
        const { token1, token2, aggregator, user, receiverContract, metaAggregatorTestSwapContract, nativeToken } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, 2 * token1Amount, token2Amount);

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapParams)

        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")).to.be.reverted
    })
    it("should revert when token swapped out are not equal to min amount out for swap erc20 delegate function", async () => {
        const { token1, token2, aggregator, user, receiverContract, metaAggregatorTestSwapContract, nativeToken } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const token2Amount = 100000000;

        await token1.mint(receiverContract.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, token1Amount, token2Amount);

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount * 2,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapParams)

        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")).to.be.reverted
    })
    it("should revert when ETH swapped out are not equal to min amount out for swap erc20 delegate function", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, metaAggregatorTestSwapContract } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;

        const tx = await executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });

        await token1.mint(receiverContract.address, token1Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount);

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: 2 * nativeTokenAmount,
            receiver: receiverContract.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }
        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapParams)

        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")).to.be.reverted
    })
    it("should revert when ETH swapped out fails for swap erc20 delegate function", async () => {
        const { token1, aggregator, metaAggregatorTestManager, nativeToken, executor, user, receiverContract, metaAggregatorTestSwapContract, receiverRevert } = await loadFixture(setupTest);

        const token1Amount = 100000000;
        const nativeTokenAmount = 100000000;

        const tx = await executor.sendTransaction({
            to: aggregator.address,
            value: nativeTokenAmount
        });

        await token1.mint(receiverContract.address, token1Amount);


        const swapData = await aggregator.populateTransaction.swap(token1.address, nativeToken, token1Amount, nativeTokenAmount);

        const swapParams = {
            tokenIn: token1.address,
            tokenOut: nativeToken,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: nativeTokenAmount,
            receiver: receiverRevert.address,
            isDelegate: false,
            targets: [],
            calldataArray: []
        }

        const delegateSwapData = await metaAggregatorTestSwapContract.populateTransaction.swapERC20(swapParams)

        await expect(receiverContract.connect(user).executeDelegate(metaAggregatorTestSwapContract.address, delegateSwapData.data || " ")).to.be.reverted
    })
    it("should fail when fee is not equal to the sum of fee receiver amount", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, feeReceiver1, feeReceiver2, metaAggregatorTestSwapContract } = await loadFixture(setupTest);
        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const token1Amount = "594675716556465465156456456";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(token1Amount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)



        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const feeTransferData1 = await token1.populateTransaction.transfer(feeReceiver1.address, feeReceiver1Amount)
        const feeTransferData2 = await token1.populateTransaction.transfer(feeReceiver2.address, feeReceiver2Amount)

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, amountAfterFee, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapETHParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [token1.address],
            calldataArray: [feeTransferData1.data || "", feeTransferData2.data || ""]
        };

        await expect(metaAggregatorTestManager.connect(user).swap(swapETHParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidTargetsCalldataLength")
    })

    it("should fail when fee values are not equal to fee receivers", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, feeReceiver1, feeReceiver2 } = await loadFixture(setupTest);

        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const nativeTokenAmount = "59467571655646";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(nativeTokenAmount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)

        await token2.mint(aggregator.address, token2Amount);


        expect(fee).to.be.equal(new BigNumber(feeReceiver1Amount).plus(new BigNumber(feeReceiver2Amount)).toFixed(0))

        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, amountAfterFee, token2Amount);

        const swapETHParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [feeReceiver1.address],
            values: [feeReceiver1Amount, feeReceiver2Amount]
        };

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapETHParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "InvalidTargetsValuesLength")
    })

    it("should fail when fee in ERC20 transfer fails", async () => {
        const { token1, token2, aggregator, metaAggregatorTestManager, user, feeReceiver1, feeReceiver2, metaAggregatorTestSwapContract } = await loadFixture(setupTest);
        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const token1Amount = "594675716556465465156456456";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(token1Amount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)



        await token1.mint(user.address, token1Amount);
        await token2.mint(aggregator.address, token2Amount);


        const feeTransferData1 = await token1.populateTransaction.transfer(feeReceiver1.address, BigInt(2 * Number(token1Amount)))
        const feeTransferData2 = await token1.populateTransaction.transfer(feeReceiver2.address, feeReceiver2Amount)

        const swapData = await aggregator.populateTransaction.swap(token1.address, token2.address, amountAfterFee, token2Amount);

        const tnx = await token1.connect(user).approve(metaAggregatorTestManager.address, token1Amount)
        await tnx.wait();

        const swapETHParams = {
            tokenIn: token1.address,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: token1Amount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [token1.address, token1.address],
            calldataArray: [feeTransferData1.data || "", feeTransferData2.data || ""]
        };

        await expect(metaAggregatorTestManager.connect(user).swap(swapETHParams)).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "FeeTransferFailed")
    })
    it("should fail when fee transfer fails for native token", async () => {
        const { token2, aggregator, metaAggregatorTestSwapContract, nativeToken, user, feeReceiver1, feeReceiver2 } = await loadFixture(setupTest);

        const feePercentage = 7.5
        const feeReceiver1Percentage = 33.55;
        const nativeTokenAmount = "59467571655646";
        const token2Amount = 100000000;

        const { amountAfterFee, fee } = calculateFee(nativeTokenAmount, feePercentage)
        const { feeReceiver1: feeReceiver1Amount, feeReceiver2: feeReceiver2Amount } = divideFee(fee, feeReceiver1Percentage)

        await token2.mint(aggregator.address, token2Amount);


        expect(fee).to.be.equal(new BigNumber(feeReceiver1Amount).plus(new BigNumber(feeReceiver2Amount)).toFixed(0))

        const swapData = await aggregator.populateTransaction.swap(nativeToken, token2.address, amountAfterFee, token2Amount);

        const swapETHParams = {
            tokenIn: nativeToken,
            tokenOut: token2.address,
            aggregator: aggregator.address,
            swapData: swapData.data || "",
            amountIn: nativeTokenAmount,
            minAmountOut: token2Amount,
            receiver: user.address,
            isDelegate: false,
            targets: [feeReceiver1.address, feeReceiver2.address],
            values: [2 * Number(nativeTokenAmount), feeReceiver2Amount]
        };

        await expect(metaAggregatorTestSwapContract.connect(user).swapETH(swapETHParams, { value: nativeTokenAmount })).to.be.revertedWithCustomError(metaAggregatorTestSwapContract, "FeeTransferFailed")
    })
})
