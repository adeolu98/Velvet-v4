// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { ErrorLibrary } from "../../library/ErrorLibrary.sol";

contract ExternalPositionManagement {
  function _handleWrappedPositionIncrease(
    address[] memory _target,
    bytes[] memory _callData
  ) internal {
    uint256 callDataLength = _callData.length;
    for (uint256 j; j < callDataLength; j++) {
      (bool success, ) = _target[j].call(_callData[j]);
      if (!success) revert ErrorLibrary.IncreaseLiquidityFailed();
    }
  }

  function _handleWrappedPositionDecrease(
    address _target,
    bytes memory _callData
  ) internal {
    (bool success, ) = _target.call(_callData);
    if (!success) revert ErrorLibrary.DecreaseLiquidityFailed();
  }
}
