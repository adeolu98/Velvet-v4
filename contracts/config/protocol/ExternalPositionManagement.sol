// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {OwnableCheck} from "./OwnableCheck.sol";

import {ErrorLibrary} from "../../library/ErrorLibrary.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/Initializable.sol";

abstract contract ExternalPositionManagement is OwnableCheck, Initializable {
  /// @notice Address of the base implementation used for creating new position wrapper instances via cloning.
  address public positionWrapperBaseImplementation;

  event PositionWrapperBaseAddressUpdated(address _newAddress);

  function __ExternalPositionManagement_init(
    address _positionWrapperBaseAlgebra
  ) internal onlyInitializing {
    _updatePositionWrapperBaseImplementationAlgebra(
      _positionWrapperBaseAlgebra
    );
  }

  /**
   * @notice Updates the base implementation address used for creating new position wrappers.
   * @dev Allows the contract's asset manager to update the reference implementation for position wrappers.
   *      This is useful when upgrading the wrapper logic without disrupting existing wrappers. The function ensures
   *      that the new address is valid and not the zero address to prevent potential issues.
   * @param _positionWrapperBaseImplementation The new base implementation address to be used for cloning new wrappers.
   */
  function _updatePositionWrapperBaseImplementationAlgebra(
    address _positionWrapperBaseImplementation
  ) internal onlyProtocolOwner {
    // Check if the new base implementation address is not the zero address.
    if (_positionWrapperBaseImplementation == address(0))
      revert ErrorLibrary.InvalidAddress();

    // Update the base implementation address stored in the contract.
    positionWrapperBaseImplementation = _positionWrapperBaseImplementation;
  }

  function updatePositionWrapperBaseImplementationAlgebra(
    address _positionWrapperBaseImplementation
  ) external onlyProtocolOwner {
    _updatePositionWrapperBaseImplementationAlgebra(
      _positionWrapperBaseImplementation
    );
    emit PositionWrapperBaseAddressUpdated(_positionWrapperBaseImplementation);
  }
}
