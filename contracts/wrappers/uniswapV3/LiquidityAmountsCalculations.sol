// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { IPositionWrapper } from "../abstract/IPositionWrapper.sol";
import { IFactory } from "../uniswapV3/IFactory.sol";
import { IPool } from "./IPool.sol";

import "@cryptoalgebra/integral-core/contracts/libraries/FullMath.sol";
import "@cryptoalgebra/integral-core/contracts/libraries/Constants.sol";

import "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";

import { LiquidityAmounts } from "../abstract/LiquidityAmounts.sol";

library LiquidityAmountsCalculations {
  function _getUnderlyingAmounts(
    IPositionWrapper _positionWrapper,
    address _factory,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 _existingLiquidity
  ) public returns (uint256 amount0, uint256 amount1) {
    IFactory factory = IFactory(_factory);
    IPool pool = IPool(
      factory.getPool(
        _positionWrapper.token0(),
        _positionWrapper.token1(),
        _positionWrapper.initialFee()
      )
    );

    int24 tick = pool.slot0().tick;
    uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

    (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
      sqrtRatioX96,
      sqrtRatioAX96,
      sqrtRatioBX96,
      _existingLiquidity
    );
  }

  function getRatioForTicks(
    IPositionWrapper _positionWrapper,
    address _factory,
    address _token0,
    address _token1,
    int24 _tickLower,
    int24 _tickUpper
  ) internal returns (uint256 ratio, address tokenZeroBalance) {
    uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower);
    uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper);

    (uint256 amount0, uint256 amount1) = _getUnderlyingAmounts(
      _positionWrapper,
      _factory,
      sqrtRatioAX96,
      sqrtRatioBX96,
      1 ether //@audit why is existing liquidity always 1e18?
    );

    if (amount0 == 0) {
      ratio = 0;
      tokenZeroBalance = _token0;
    } else if (amount1 == 0) {
      ratio = 0;
      tokenZeroBalance = _token1;
    } else {
      ratio = (amount0 * 1e18) / amount1;
    }
  }
}
