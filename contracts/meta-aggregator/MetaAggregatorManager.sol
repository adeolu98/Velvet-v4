// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IMetaAggregatorSwapContract} from "./interfaces/IMetaAggregatorSwapContract.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaAggregatorManager} from "./interfaces/IMetaAggregatorManager.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
/**
 * @title MetaAggregatorManager
 * @dev This contract manages the swapping of tokens through a meta aggregator.
 */
contract MetaAggregatorManager is ReentrancyGuard, IMetaAggregatorManager {
    IMetaAggregatorSwapContract immutable MetaAggregatorSwap;
    address nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Custom error definitions
    error CannotSwapETH();
    error InvalidMetaAggregatorAddress();


    /**
     * @dev Sets the address of the MetaAggregatorSwap contract.
     * @param _metaAggregatorSwap The address of the MetaAggregatorSwap contract.
     */
    constructor(address _metaAggregatorSwap) {
         if(_metaAggregatorSwap == address(0)) {
            revert InvalidMetaAggregatorAddress();
        }
        MetaAggregatorSwap = IMetaAggregatorSwapContract(_metaAggregatorSwap);
    }

    /**
     * @dev Swaps tokens using the MetaAggregatorSwap contract.
     * @param tokenIn The input token (ERC20).
     * @param tokenOut The output token (ERC20).
     * @param aggregator The address of the aggregator to perform the swap.
     * @param swapData The data required for the swap.
     * @param amountIn The amount of tokenIn to swap.
     * @param minAmountOut The minimum amount of tokenOut expected.
     * @param receiver The address to receive the output tokens.
     * @param isDelegate Whether to use delegatecall for the swap.
     * @notice This function is non-reentrant to prevent reentrancy attacks.
     */
    function swap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address aggregator,
        bytes calldata swapData,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bool isDelegate
    ) external nonReentrant {
        // Check if the input token is the native token (ETH)
        if (address(tokenIn) == nativeToken) {
            revert CannotSwapETH();
        }

        TransferHelper.safeTransferFrom(address(tokenIn), msg.sender, address(MetaAggregatorSwap), amountIn);

        MetaAggregatorSwap.swapERC20(
            tokenIn,
            tokenOut,
            aggregator,
            swapData,
            amountIn,
            minAmountOut,
            receiver,
            isDelegate
        );
    }
}
