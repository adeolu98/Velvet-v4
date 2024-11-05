// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { PositionManagerAbstractAlgebra, ErrorLibrary } from "../algebra/PositionManagerAlgebraAbstract.sol";

/**
 * @title PositionManagerCamelot
 * @dev Concrete implementation of the PositionManagerAbstract contract.
 * This contract inherits all functionalities from PositionManagerAbstract and serves as the final implementation.
 */
contract PositionManagerCamelot is PositionManagerAbstractAlgebra {
  function init(
    address _protocolConfig,
    address _assetManagerConfig,
    address _accessController
  ) external initializer {
    // Add input validation
    if (
      _protocolConfig == address(0) ||
      _assetManagerConfig == address(0) ||
      _accessController == address(0)
    ) revert ErrorLibrary.InvalidAddress();

    PositionManagerAbstractAlgebra_init(
      0x00c7f3082833e796A5b3e4Bd59f6642FF44DCD15,
      0xE592427A0AEce92De3Edee1F18E0157C05861564, // Uniswap router for testing
      _protocolConfig,
      _assetManagerConfig,
      _accessController
    );
  }
}
