// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IPool {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function liquidity() external view returns (uint128);
}
