// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaAggregatorSwapContract} from "./interfaces/IMetaAggregatorSwapContract.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";

/**
 * @title MetaAggregatorSwapContract
 * @dev Facilitates swapping between ETH and ERC20 tokens or between two ERC20 tokens using an aggregator.
 */
contract MetaAggregatorSwapContract is IMetaAggregatorSwapContract {
    address constant nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // Represent native ETH token
    address immutable usdt; // Address of USDT token
    address immutable SWAP_TARGET; // Address of the swap target for delegatecall operations
    address immutable _this; // Address of this contract instance
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // Custom error messages for efficient error handling
    error CannotSwapTokens();
    error AmountInMustBeGreaterThanZero();
    error MinAmountOutMustBeGreaterThanZero();
    error TokenInAndTokenOutCannotBeSame();
    error IncorrectEtherAmountSent();
    error CannotSwapETHToETH();
    error InvalidReceiver();
    error InvalidENSOAddress();
    error InvalidUSDTAddress();
    error InsufficientOutputBalance();
    error InsufficientETHOutAmount();
    error InsufficientTokenOutAmount();
    error SwapFailed();
    error CannotSwapETH();
    error InvalidTargetsCalldataLength();
    error TargetCallFailed();
    error InvalidTargetsValuesLength();

    //   Event emitted when ETH is swapped for an ERC20 token
    event ETHSwappedForToken(
        uint256 indexed amountOut,
        address indexed tokenOut,
        address indexed receiver
    );

    // Event emitted when an ERC20 token is swapped for another ERC20 token
    event ERC20Swapped(
        uint256 indexed amountOut,
        address indexed tokenIn,
        address indexed tokenOut,
        address receiver
    );

    /**
     * @dev Initializes the contract with the swap target and USDT targets.
     * @param _ensoSwapContract The address of the swap target contract.
     * @param _usdt The address of the USDT token.
     */
    constructor(address _ensoSwapContract, address _usdt) {
        if (_ensoSwapContract == address(0)) revert InvalidENSOAddress();
        if (_usdt == address(0)) revert InvalidUSDTAddress();
        SWAP_TARGET = _ensoSwapContract;
        usdt = _usdt;
        _this = address(this);
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev only checks for re-entrancy when the call is not delegate.
     */
    function _nonReentrantBefore() private {
        if (address(this) == _this) {
            // On the first call to nonReentrant, _status will be _NOT_ENTERED
            require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

            // Any calls to nonReentrant after this point will fail
            _status = _ENTERED;
        }
    }

    /**
     * @dev only checks for re-entrancy when the call is not delegate.
     */
    function _nonReentrantAfter() private {
        if (address(this) == _this) {
            // By storing the original value once again, a refund is triggered (see
            // https://eips.ethereum.org/EIPS/eip-2200)
            _status = _NOT_ENTERED;
        }
    }

    /// @notice Executes a token swap using the MetaAggregatorSwap contract
    /// @param params The parameters required for the swap, encapsulated in the SwapETHParams struct
    /// @dev This function checks if the input token is the native token (ETH) and reverts if so.
    function swapETH(
        SwapETHParams calldata params
    ) external payable nonReentrant {
        if (address(params.tokenIn) != nativeToken) {
            revert CannotSwapTokens();
        }
        uint256 amountOut = _swapETH(params);
        emit ETHSwappedForToken(
            amountOut,
            address(params.tokenOut),
            params.receiver
        );
    }

    /// @notice Executes a token swap using the MetaAggregatorSwap contract
    /// @param params The parameters required for the swap, encapsulated in the SwapERC20Params struct
    /// @dev This function checks if the input token is the native token (ETH) and reverts if so.
    function swapERC20(SwapERC20Params calldata params) external nonReentrant {
        uint256 amountOut = _swapERC20(params);
        emit ERC20Swapped(
            amountOut,
            address(params.tokenIn),
            address(params.tokenOut),
            params.receiver
        );
    }

    function _swapETH(
        SwapETHParams calldata params
    ) internal returns (uint256) {
        _validateInputs(
            params.tokenIn,
            address(params.tokenOut),
            params.amountIn,
            params.minAmountOut,
            params.receiver
        );

        if(params.targets.length != params.values.length) revert InvalidTargetsValuesLength();

        {
            for (uint256 i = 0; i < params.targets.length; i++) {
                (bool success, ) = params.targets[i].call{
                    value: params.values[i]
                }("");
                if (!success) revert SwapFailed();
            }
        }

        if (msg.value < params.amountIn) revert IncorrectEtherAmountSent();

        uint256 balanceBefore = params.tokenOut.balanceOf(address(this));
        _executeAggregatorCall(
            params.swapData,
            params.isDelegate,
            params.aggregator,
            params.amountIn
        );
        uint256 amountOut = params.tokenOut.balanceOf(address(this)) -
            balanceBefore;

        if (amountOut < params.minAmountOut) revert InsufficientOutputBalance();
        if (params.receiver != address(this)) {
            TransferHelper.safeTransfer(
                address(params.tokenOut),
                params.receiver,
                amountOut
            );
        }
        return amountOut;
    }

    function _swapERC20(
        SwapERC20Params calldata params
    ) internal returns (uint256) {
        _validateInputs(
            address(params.tokenIn),
            address(params.tokenOut),
            params.amountIn,
            params.minAmountOut,
            params.receiver
        );

        if(params.targets.length != params.calldataArray.length) revert InvalidTargetsCalldataLength();
        {
            for (uint256 i = 0; i < params.targets.length; i++) {
                (bool success, ) = params.targets[i].call(
                    params.calldataArray[i]
                );
                if (!success) revert SwapFailed();
            }
        }

        if (!params.isDelegate) {
            if (address(params.tokenIn) == usdt)
                TransferHelper.safeApprove(
                    address(params.tokenIn),
                    params.aggregator,
                    0
                );
            TransferHelper.safeApprove(
                address(params.tokenIn),
                params.aggregator,
                params.amountIn
            );
        }

        uint256 amountOut;
        if (address(params.tokenOut) == nativeToken) {
            uint256 balanceBefore = address(this).balance;
            _executeAggregatorCall(
                params.swapData,
                params.isDelegate,
                params.aggregator,
                0
            );
            amountOut = address(this).balance - balanceBefore;
            if (amountOut < params.minAmountOut)
                revert InsufficientETHOutAmount();
            if (params.receiver != address(this)) {
                (bool success, ) = params.receiver.call{value: amountOut}("");
                if (!success) revert SwapFailed();
            }
        } else {
            uint256 balanceBefore = params.tokenOut.balanceOf(address(this));
            _executeAggregatorCall(
                params.swapData,
                params.isDelegate,
                params.aggregator,
                0
            );
            amountOut =
                params.tokenOut.balanceOf(address(this)) -
                balanceBefore;
            if (amountOut < params.minAmountOut)
                revert InsufficientTokenOutAmount();

            if (params.receiver != address(this)) {
                TransferHelper.safeTransfer(
                    address(params.tokenOut),
                    params.receiver,
                    amountOut
                );
            }
        }

        return amountOut;
    }

    /**
     * @dev Executes a swap call via the aggregator or delegatecall context.
     * @param swapData The data required for the swap.
     * @param isDelegate Indicates if the swap is in a delegatecall context.
     * @param aggregator The address of the aggregator to use for the swap.
     * @param value The amount of ETH to send with the call (if applicable).
     */
    function _executeAggregatorCall(
        bytes memory swapData,
        bool isDelegate,
        address aggregator,
        uint256 value
    ) internal {
        (bool success, bytes memory returnData) = isDelegate
            ? SWAP_TARGET.delegatecall(swapData)
            : aggregator.call{value: value}(swapData);

        if (!success) {
            assembly {
                let size := mload(returnData)
                revert(add(32, returnData), size)
            }
        }
    }

    /**
     * @dev Validates the swap inputs for consistency and correctness.
     * @param tokenIn address of tokenIn
     * @param tokenOut address of tokenIn
     * @param amountIn The amount of tokenIn to swap.
     * @param minAmountOut The minimum amount of tokenOut expected.
     * @param receiver The address to receive the tokenOut.
     */
    function _validateInputs(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver
    ) internal pure {
        if (receiver == address(0)) revert InvalidReceiver();
        if (amountIn == 0) revert AmountInMustBeGreaterThanZero();
        if (minAmountOut == 0) revert MinAmountOutMustBeGreaterThanZero();
        if (tokenIn == tokenOut) revert TokenInAndTokenOutCannotBeSame();
    }

    /**
     * @dev Allows the contract to receive ETH.
     */
    receive() external payable {}
}
