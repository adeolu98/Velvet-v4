// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMetaAggregatorManager {
    
    /// @notice Struct to hold parameters for the ERC20 swap operation
    /// @param tokenIn The ERC20 token to swap from
    /// @param tokenOut The ERC20 token to swap to
    /// @param aggregator The address of the aggregator to use for the swap
    /// @param swapData Additional data required for the swap
    /// @param amountIn The amount of tokenIn to swap
    /// @param minAmountOut The minimum amount of tokenOut expected from the swap
    /// @param receiver The address that will receive the tokenOut
    /// @param isDelegate Indicates if the swap is being executed by a delegate
    /// @param targets Array of addresses to call during the swap for fees
    /// @param calldataArray Array of calldata for each target for fees
    struct SwapERC20Params {
        IERC20 tokenIn;
        IERC20 tokenOut;
        address aggregator;
        bytes swapData;
        uint256 amountIn;
        uint256 minAmountOut;
        address receiver;
        bool isDelegate;
        address[] targets;
        bytes[] calldataArray;
    }

    function swap(SwapERC20Params calldata params) external;
}
