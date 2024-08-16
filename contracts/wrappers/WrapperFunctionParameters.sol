// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title WrapperFunctionParameters
 * @dev Library containing structures for function parameters used in the wrapper contract.
 * This library is used to define and organize the parameters required for minting positions in a structured format.
 */
library WrapperFunctionParameters {
  /**
   * @dev Struct for parameters required to mint a new position.
   * @param _name The name of the ERC20 token representing the position.
   * @param _symbol The symbol of the ERC20 token representing the position.
   * @param _token0 The address of the first token in the pair.
   * @param _token1 The address of the second token in the pair.
   * @param _amount0Desired The desired amount of token0 to be added to the position.
   * @param _amount1Desired The desired amount of token1 to be added to the position.
   * @param _amount0Min The minimum amount of token0 to be added to the position.
   * @param _amount1Min The minimum amount of token1 to be added to the position.
   * @param _tickLower The lower tick boundary for the position.
   * @param _tickUpper The upper tick boundary for the position.
   */
  struct PositionMintParams {
    uint256 _amount0Desired;
    uint256 _amount1Desired;
    uint256 _amount0Min;
    uint256 _amount1Min;
    uint24 _fee;
    int24 _tickLower;
    int24 _tickUpper;
  }

  struct InitialMintParams {
    uint256 _amount0Desired;
    uint256 _amount1Desired;
    uint256 _amount0Min;
    uint256 _amount1Min;
  }

  // THENA
  /**
   * @dev Struct for parameters required to mint a new position.
   * @param _name The name of the ERC20 token representing the position.
   * @param _symbol The symbol of the ERC20 token representing the position.
   * @param _token0 The address of the first token in the pair.
   * @param _token1 The address of the second token in the pair.
   * @param _amount0Desired The desired amount of token0 to be added to the position.
   * @param _amount1Desired The desired amount of token1 to be added to the position.
   * @param _amount0Min The minimum amount of token0 to be added to the position.
   * @param _amount1Min The minimum amount of token1 to be added to the position.
   * @param _tickLower The lower tick boundary for the position.
   * @param _tickUpper The upper tick boundary for the position.
   */
  struct PositionMintParamsThena {
    uint256 _amount0Desired;
    uint256 _amount1Desired;
    uint256 _amount0Min;
    uint256 _amount1Min;
    int24 _tickLower;
    int24 _tickUpper;
  }
}
