// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { ErrorLibrary } from "../../library/ErrorLibrary.sol";

import { IAccessController } from "../../access/IAccessController.sol";

contract ExternalPositionStorage {
  IAccessController accessController;
  /// @notice Mapping to check if a given address is an officially deployed wrapper position.
  /// @dev Helps in validating whether interactions are with legitimate wrappers.
  mapping(address => bool) public isWrappedPosition;

  function addWrappedPosition(address _newPostion) external {
    if (!accessController.hasRole(keccak256("POSITION_MANAGER"), msg.sender))
      revert ErrorLibrary.CallerNotSuperAdmin();
    isWrappedPosition[_newPostion] = true;
  }
}
