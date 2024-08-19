// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { LiquidityAmounts } from "./LiquidityAmounts.sol";
import { INonfungiblePositionManager } from "../../wrappers/algebra/INonfungiblePositionManager.sol";

import "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";

import { IFactory } from "../../wrappers/algebra/IFactory.sol";
import { IPool } from "../../wrappers/interfaces/IPool.sol";

import { IPositionWrapper } from "../../wrappers/abstract/IPositionWrapper.sol";

contract AmountCalculationsAlgebra {
  INonfungiblePositionManager internal uniswapV3PositionManager =
    INonfungiblePositionManager(0xa51ADb08Cbe6Ae398046A23bec013979816B77Ab);

  uint256 constant TOTAL_WEIGHT = 10_000;

  function getUnderlyingAmounts(
    IPositionWrapper _positionWrapper
  ) public returns (uint256 amount0, uint256 amount1) {
    (
      ,
      ,
      ,
      ,
      int24 tickLower,
      int24 tickUpper,
      uint128 existingLiquidity,
      ,
      ,
      ,

    ) = uniswapV3PositionManager.positions(_positionWrapper.tokenId());

    IFactory factory = IFactory(uniswapV3PositionManager.factory());
    IPool pool = IPool(
      factory.poolByPair(_positionWrapper.token0(), _positionWrapper.token1())
    );

    int24 tick = pool.globalState().tick;
    uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
    uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
    uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

    (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
      sqrtRatioX96,
      sqrtRatioAX96,
      sqrtRatioBX96,
      existingLiquidity
    );
  }

  function getLiquidityAmountsForPartialWithdrawal(
    IPositionWrapper _positionWrapper,
    uint256 _percentage // wrapper balance / total supply
  ) external returns (uint256 amount0Out, uint256 amount1Out) {
    require(
      _percentage <= TOTAL_WEIGHT,
      "Percentage should be less than or equal to 10000"
    );
    (uint256 amount0, uint256 amount1) = getUnderlyingAmounts(_positionWrapper);

    amount0Out = (amount0 * _percentage) / TOTAL_WEIGHT;
    amount1Out = (amount1 * _percentage) / TOTAL_WEIGHT;
  }

  function getPercentage(
    uint256 _partially,
    uint256 _total
  ) external pure returns (uint256 percentage) {
    percentage = (_partially * TOTAL_WEIGHT) / _total;
  }
}
