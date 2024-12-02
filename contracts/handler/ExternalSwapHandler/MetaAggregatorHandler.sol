// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable-4.9.6/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { TransferHelper } from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import { ErrorLibrary } from "../../library/ErrorLibrary.sol";
import { IIntentHandler } from "../IIntentHandler.sol";
import { IPositionManager } from "../../wrappers/abstract/IPositionManager.sol";
import { FunctionParameters } from "../../FunctionParameters.sol";
import { ExternalPositionManagement } from "./ExternalPositionManagement.sol";

/**
 * @title MetaAggregatorHandler
 * @dev This contract is designed to interface with the Enso platform, facilitating
 * the execution of token swaps and the subsequent transfer of swap outputs. It leverages
 * delegatecall for swap execution, allowing for the integration of complex swap operations
 * and strategies specific to the Enso ecosystem. Additionally, it includes mechanisms for
 * the secure handling of token transfers, including adherence to minimum expected output
 * thresholds for swap operations.
 */
contract MetaAggregatorHandler is ExternalPositionManagement {
  // The address of Enso's swap execution logic; swaps are delegated to this target.
  address constant SWAP_TARGET = 0xfDAc2748713906ede00D023AA3E0Cc893828D30B; // manager contract

  /**
   * @notice Conducts a rebalance operation via the Solver platform and transfers the output tokens
   * to a specified recipient address.
   * @param _params Encoded bundle containing the rebalance operation data, structured as follows:
   *        - positionManager: Address of the Enso Position Manager contract.
   *        - to: Address of the recipient for the rebalance operation.
   *        - calldata: Encoded call data for the rebalance operation.
   * @return _swapReturns Array containing the actual amounts of tokens received from each swap operation.
   */
  function multiTokenSwapAndTransferRebalance(
    FunctionParameters.EnsoRebalanceParams memory _params
  ) external returns (address[] memory) {
    // Decode the input parameters
    (
      bytes[][] memory callDataEnso, // Array of arrays containing encoded swap data for Enso platform
      // Two-dimensional because each external position might require multiple swaps
      bytes[] memory callDataDecreaseLiquidity, // Array of encoded data for decreasing liquidity
      // Includes token approval and liquidity removal for each position
      bytes[][] memory callDataIncreaseLiquidity, // Array of arrays with encoded data for increasing liquidity
      // Two-dimensional as each position may need multiple steps (approval, adding liquidity)
      address[][] memory increaseLiquidityTarget, // Array of arrays with target addresses for increasing liquidity
      // Two-dimensional to match the structure of callDataIncreaseLiquidity
      address[] memory underlyingTokensDecreaseLiquidity, // Array of underlying tokens for decreasing liquidity
      // One-dimensional as it's a flat list of tokens
      address[] memory tokensIn, // Array of input token addresses
      address[] memory tokensOut, // Array of output token addresses
      uint256[][] memory swapAmounts,
      uint256[] memory minExpectedOutputAmounts // Array of minimum expected output amounts
    ) = abi.decode(
        _params._calldata,
        (
          bytes[][],
          bytes[],
          bytes[][],
          address[][],
          address[],
          address[],
          address[],
          uint256[][],
          uint256[]
        )
      );

    _validateInputParameters(
      _params,
      callDataEnso,
      callDataIncreaseLiquidity,
      increaseLiquidityTarget,
      tokensOut,
      tokensIn,
      minExpectedOutputAmounts
    );

    _handleTokenTransfer(
      _params,
      callDataDecreaseLiquidity,
      callDataIncreaseLiquidity,
      increaseLiquidityTarget,
      callDataEnso,
      tokensIn,
      tokensOut,
      swapAmounts,
      minExpectedOutputAmounts
    );

    _returnDust(underlyingTokensDecreaseLiquidity, _params._to);

    return tokensOut;
  }

  function _handleTokenTransfer(
    FunctionParameters.EnsoRebalanceParams memory _params,
    bytes[] memory callDataDecreaseLiquidity,
    bytes[][] memory callDataIncreaseLiquidity,
    address[][] memory increaseLiquidityTarget,
    bytes[][] memory callDataEnso,
    address[] memory tokensIn,
    address[] memory tokensOut,
    uint256[][] memory swapAmounts,
    uint256[] memory minExpectedOutputAmounts
  ) internal {
    for (uint256 i; i < tokensOut.length; i++) {
      address token = tokensOut[i]; // Optimize gas by caching the token address.
      uint256 buyBalanceBefore = IERC20Upgradeable(token).balanceOf(
        address(this)
      );

      // Handle wrapped positions for input tokens: Decreases liquidity from wrapped positions
      if (
        address(_params._positionManager) != address(0) && // PositionManager has not been initialized
        _params._positionManager.isWrappedPosition(tokensIn[i])
      ) {
        _handleWrappedPositionDecrease(
          address(_params._positionManager),
          callDataDecreaseLiquidity[i]
        );
      }

      // Execute swaps
      _executeSwaps(callDataEnso[i], tokensIn[i], swapAmounts[i]); // @todo set amount

      // Handle wrapped positions for output tokens: Approves position manager to spend underlying tokens + increases liquidity
      if (
        address(_params._positionManager) != address(0) && // PositionManager has not been initialized
        _params._positionManager.isWrappedPosition(token)
      ) {
        _handleWrappedPositionIncrease(
          increaseLiquidityTarget[i],
          callDataIncreaseLiquidity[i]
        );
      }

      _transferTokensAndVerify(
        token,
        _params._to,
        buyBalanceBefore,
        minExpectedOutputAmounts[i]
      );
    }
  }

  function _validateInputParameters(
    FunctionParameters.EnsoRebalanceParams memory _params,
    bytes[][] memory callDataEnso,
    bytes[][] memory callDataIncreaseLiquidity,
    address[][] memory increaseLiquidityTarget,
    address[] memory tokensOut,
    address[] memory tokensIn,
    uint256[] memory minExpectedOutputAmounts
  ) internal pure {
    // Validate lengths of input arrays for consistency.
    uint256 tokensLength = tokensOut.length;

    if (
      tokensLength != minExpectedOutputAmounts.length ||
      tokensLength != callDataEnso.length ||
      callDataIncreaseLiquidity.length != increaseLiquidityTarget.length ||
      tokensIn.length != tokensLength
    ) revert ErrorLibrary.InvalidLength();

    // Ensure the recipient address is valid.
    if (_params._to == address(0)) revert ErrorLibrary.InvalidAddress();
  }

  /// @notice Executes a series of swap operations
  /// @dev This function iterates through the provided swap call data and executes each swap
  /// @param _swapCallData An array of bytes containing the encoded swap instructions
  /// @custom:security This function uses delegatecall, which can be dangerous if not properly secured
  /// @custom:gas-optimization Uses cached array length to save gas in the loop

  function _executeSwaps(
    bytes[] memory _swapCallData,
    address _sellToken,
    uint256[] memory _sellAmount
  ) private {
    uint256 swapCallDataLength = _swapCallData.length;
    for (uint256 j; j < swapCallDataLength; j++) {
      TransferHelper.safeApprove(_sellToken, SWAP_TARGET, 0);
      TransferHelper.safeApprove(_sellToken, SWAP_TARGET, _sellAmount[j]);

      (bool success, ) = SWAP_TARGET.delegatecall(_swapCallData[j]);
      if (!success) revert ErrorLibrary.CallFailed();
    }
  }

  // Function to receive Ether when msg.data is empty
  receive() external payable {}
}
