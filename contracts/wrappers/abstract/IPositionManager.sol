// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { WrapperFunctionParameters } from "../WrapperFunctionParameters.sol";
import { IPositionWrapper } from "./IPositionWrapper.sol";

/**
 * @title IPositionManager
 * @dev Interface for a Position Manager contract that coordinates interactions
 * between Uniswap V3 positions and external systems like asset management or access control.
 * This interface facilitates the initialization of position manager instances, updating base
 * implementations for position wrappers, and querying wrapped positions.
 */
interface IPositionManager {
  /**
   * @notice Initializes the Position Manager with configuration settings.
   * @dev Sets up the position manager with necessary configurations including
   * asset management settings, access control, and a base implementation for position wrappers.
   * @param _assetManagerConfig Address of the asset management configuration contract.
   * @param _accessController Address of the access control contract.
   */
  function init(
    address _protocolConfig,
    address _assetManagerConfig,
    address _accessController
  ) external;

  /**
   * @notice Updates the base implementation address for position wrappers.
   * @dev This allows the position manager to adapt to new wrapper implementations without disrupting existing positions.
   * Useful in upgrading the system or correcting issues in previous implementations.
   * @param _positionWrapperBaseImplementation The new base implementation address to be used for creating position wrappers.
   */
  function updatePositionWrapperBaseImplementation(
    address _positionWrapperBaseImplementation
  ) external;

  /**
   * @notice Checks if a given address is a recognized and valid wrapped position.
   * @dev This function is typically used to verify if a particular contract address corresponds
   * to a valid position wrapper managed by this system, ensuring that interactions are limited
   * to legitimate and tracked wrappers.
   * @return bool Returns true if the address corresponds to a wrapped position, false otherwise.
   */
  function isWrappedPosition(address) external returns (bool);

  function initializePositionAndDeposit(
    address _dustReceiver,
    IPositionWrapper _positionWrapper,
    WrapperFunctionParameters.InitialMintParams memory params
  ) external;

  function increaseLiquidity(
    WrapperFunctionParameters.WrapperDepositParams memory _params
  ) external;

  function decreaseLiquidity(
    address _positionWrapper,
    uint256 _withdrawalAmount,
    uint256 _amount0Min,
    uint256 _amount1Min,
    // swap params
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external;
}
