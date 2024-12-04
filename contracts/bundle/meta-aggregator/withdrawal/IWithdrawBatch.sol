// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IWithdrawBatch {
  function multiTokenSwapAndWithdraw(
    address _target,
    address _tokenToWithdraw,
    address user,
    uint256 _expectedOutputAmount,
    uint256[] memory _swapAmounts,
    bytes[] memory _callData
  ) external;
}
