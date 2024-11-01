// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IMetaAggregatorSwapContract} from "./interfaces/IMetaAggregatorSwapContract.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";

/**
 * @title MetaAggregatorSwapContract
 * @dev This contract facilitates swapping between ETH and ERC20 tokens using an aggregator.
 */
contract MetaAggregatorSwapContract is
    ReentrancyGuard,
    IMetaAggregatorSwapContract
{
    address constant nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable SWAP_TARGET;

    // Custom error definitions
    error CannotSwapTokens();
    error AmountInMustBeGreaterThanZero();
    error MinAmountOutMustBeGreaterThanZero();
    error TokenInAndTokenOutCannotBeSame();
    error IncorrectEtherAmountSent();
    error CannotSwapETHToETH();
    error InsufficientOutputBalance();
    error InsufficientTokenInBalance();
    error InsufficientETHOutAmount();
    error InsufficientTokenOutAmount();
    error SwapFailed();
    error InvalidReceiver();
    error InvalidENSOAddress();

    event AmountSent(uint256 indexed amount, address indexed tokenOut);

    /**
     * @dev Sets the swap target address.
     * @param _ensoSwapContract The address of the swap target contract.
     */
    constructor(address _ensoSwapContract) {
        if(_ensoSwapContract == address(0)) {
            revert InvalidENSOAddress();
        }
        SWAP_TARGET = _ensoSwapContract;
    }

    /**
     * @dev Swaps ETH for an ERC20 token.
     * @param tokenIn The input token (must be ETH).
     * @param tokenOut The output token (ERC20).
     * @param aggregator The address of the aggregator to perform the swap.
     * @param swapData The data required for the swap.
     * @param amountIn The amount of ETH to swap.
     * @param minAmountOut The minimum amount of tokenOut expected.
     * @param receiver The address to receive the output tokens.
     * @param isDelegate Whether to use delegatecall for the swap.
     */
    function swapETH(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address aggregator,
        bytes calldata swapData,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bool isDelegate
    ) external payable nonReentrant {
        if (address(tokenIn) != nativeToken) {
            revert CannotSwapTokens();
        }
        uint256 amountOut = _swapETH(
            tokenIn,
            tokenOut,
            aggregator,
            swapData,
            amountIn,
            minAmountOut,
            receiver,
            isDelegate
        );

        emit AmountSent(amountOut, address(tokenOut));
    }

    /**
     * @dev Swaps one ERC20 token for another. Should be called from manager contract through swap function.
     * @param tokenIn The input token (ERC20).
     * @param tokenOut The output token (ERC20) or Native token (ETH).
     * @param aggregator The address of the aggregator to perform the swap.
     * @param swapData The data required for the swap.
     * @param amountIn The amount of tokenIn to swap.
     * @param minAmountOut The minimum amount of tokenOut expected.
     * @param receiver The address to receive the output tokens.
     * @param isDelegate Whether to use delegatecall for the swap.
     */
    function swapERC20(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address aggregator,
        bytes calldata swapData,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bool isDelegate
    ) external nonReentrant {
        uint256 amountOut = _swapERC20(
            tokenIn,
            tokenOut,
            aggregator,
            swapData,
            amountIn,
            minAmountOut,
            receiver,
            isDelegate
        );

        emit AmountSent(amountOut, address(tokenOut));
    }

    /**
     * @dev Internal function to perform the swap logic.
     * @param tokenIn The input token (ETH).
     * @param tokenOut The output token (ERC20).
     * @param aggregator The address of the aggregator to perform the swap.
     * @param swapData The data required for the swap.
     * @param amountIn The amount of tokenIn to swap.
     * @param minAmountOut The minimum amount of tokenOut expected.
     * @param receiver The address to receive the output tokens.
     * @param isDelegate Whether to use delegatecall for the swap.
     * @return amountOut The amount of tokenOut received.
     */
    function _swapETH(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address aggregator,
        bytes calldata swapData,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bool isDelegate
    ) internal returns (uint256 amountOut) {
        if (receiver == address(0)) {
            revert InvalidReceiver();
        }
        if (amountIn == 0) {
            revert AmountInMustBeGreaterThanZero();
        }
        if (minAmountOut == 0) {
            revert MinAmountOutMustBeGreaterThanZero();
        }
        if (address(tokenIn) == address(tokenOut)) {
            revert TokenInAndTokenOutCannotBeSame();
        }

        if (msg.value != amountIn) {
            revert IncorrectEtherAmountSent();
        }

        uint256 balanceBeforeSwap = tokenOut.balanceOf(address(this)); // Get the balance after the swap

        _callAggregator(swapData, isDelegate, aggregator);

        uint256 balanceAfterSwap = tokenOut.balanceOf(address(this));

        amountOut = balanceAfterSwap - balanceBeforeSwap;
        if (amountOut < minAmountOut) {
            revert InsufficientOutputBalance();
        }

        TransferHelper.safeTransfer(address(tokenOut), receiver, amountOut);
    }

    /**
     * @dev Internal function to perform the swap logic.
     * @param tokenIn The input token (ERC20).
     * @param tokenOut The output token (ERC20 or ETH).
     * @param aggregator The address of the aggregator to perform the swap.
     * @param swapData The data required for the swap.
     * @param amountIn The amount of tokenIn to swap.
     * @param minAmountOut The minimum amount of tokenOut expected.
     * @param receiver The address to receive the output tokens.
     * @param isDelegate Whether to use delegatecall for the swap.
     * @return amountOut The amount of tokenOut received.
     */
    function _swapERC20(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address aggregator,
        bytes calldata swapData,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bool isDelegate
    ) internal returns (uint256 amountOut) {
        if (receiver == address(0)) {
            revert InvalidReceiver();
        }
        if (amountIn == 0) {
            revert AmountInMustBeGreaterThanZero();
        }
        if (minAmountOut == 0) {
            revert MinAmountOutMustBeGreaterThanZero();
        }
        if (address(tokenIn) == address(tokenOut)) {
            revert TokenInAndTokenOutCannotBeSame();
        }

        TransferHelper.safeApprove(address(tokenIn), aggregator, 0);
        TransferHelper.safeApprove(address(tokenIn), aggregator, amountIn);

        // Check if tokenOut is native
        if (address(tokenOut) == nativeToken) {
            uint256 balanceBeforeSwap = address(this).balance; // Get the balance after the swap

            _callAggregator(swapData, isDelegate, aggregator);

            uint256 balanceAfterSwap = address(this).balance;

            amountOut = balanceAfterSwap - balanceBeforeSwap;
            if (amountOut < minAmountOut) {
                revert InsufficientETHOutAmount();
            }

            if (receiver.code.length > 0) {
                // Use call to send ETH to the contract
                (bool success, bytes memory returnData) = receiver.call{
                    value: amountOut
                }("");
                if (!success) {
                    assembly {
                        let returnData_size := mload(returnData)
                        revert(add(32, returnData), returnData_size)
                    }
                }
            } else {
                // Use transfer to send ETH to the EOA
                payable(receiver).transfer(amountOut);
            }
        } else {
            uint256 balanceBeforeSwap = tokenOut.balanceOf(address(this)); // Get the balance after the swap

            _callAggregator(swapData, isDelegate, aggregator);

            uint256 balanceAfterSwap = tokenOut.balanceOf(address(this));

            amountOut = balanceAfterSwap - balanceBeforeSwap;
            if (amountOut < minAmountOut) {
                revert InsufficientTokenOutAmount();
            }
            TransferHelper.safeTransfer(address(tokenOut), receiver, amountOut);
        }
    }

    /**
     * @dev Internal function to call the aggregator for the swap.
     * @param swapData The data required for the swap.
     * @param isDelegate Whether to use delegatecall for the swap.
     * @param aggregator The address of the aggregator to perform the swap.
     */
    function _callAggregator(
        bytes memory swapData,
        bool isDelegate,
        address aggregator
    ) internal {
        if (!isDelegate) {
            (bool success, bytes memory returnData) = aggregator.call{
                value: msg.value
            }(swapData);
            if (!success) {
                assembly {
                    let returnData_size := mload(returnData)
                    revert(add(32, returnData), returnData_size)
                }
            }
        } else {
            (bool success, bytes memory returnData) = SWAP_TARGET.delegatecall(
                swapData
            );
            if (!success) {
                assembly {
                    let returnData_size := mload(returnData)
                    revert(add(32, returnData), returnData_size)
                }
            }
        }
    }

    /**
     * @dev Fallback function to receive ETH.
     */
    receive() external payable {}
}
