//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPoolLogic {
  function getReservesList() external view returns (address[] memory);

  function getUserAccountData(address account)
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
}
