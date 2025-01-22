// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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
        if (_metaAggregatorSwap == address(0)) {
            revert InvalidMetaAggregatorAddress();
        }
        MetaAggregatorSwap = IMetaAggregatorSwapContract(_metaAggregatorSwap);
    }

    /// @notice Executes a token swap using the MetaAggregatorSwap contract
    /// @param params The parameters required for the swap, encapsulated in the SwapERC20Params struct
    /// @dev This function checks if the input token is the native token (ETH) and reverts if so.
    function swap(SwapERC20Params calldata params) external nonReentrant {
        // Check if the input token is the native token (ETH)
        if (address(params.tokenIn) == nativeToken) {
            revert CannotSwapETH();
        }

        TransferHelper.safeTransferFrom(
            address(params.tokenIn),
            msg.sender,
            address(MetaAggregatorSwap),
            params.amountIn
        );

        IMetaAggregatorSwapContract.SwapERC20Params
            memory swapParams = IMetaAggregatorSwapContract.SwapERC20Params({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                aggregator: params.aggregator,
                swapData: params.swapData,
                amountIn: params.amountIn,
                minAmountOut: params.minAmountOut,
                receiver: params.receiver,
                isDelegate: params.isDelegate,
                targets: params.targets,
                calldataArray: params.calldataArray
            });

        MetaAggregatorSwap.swapERC20(swapParams);
    }
}
