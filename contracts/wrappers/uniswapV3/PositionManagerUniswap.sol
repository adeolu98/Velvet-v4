// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { PositionManagerAbstractUniswap, ErrorLibrary } from "./PositionManagerAbstractUniswap.sol";

/**
 * @title PositionManager
 * @dev Concrete implementation of the PositionManagerAbstract contract.
 * This contract inherits all functionalities from PositionManagerAbstract and serves as the final implementation.
 */
contract PositionManagerUniswap is PositionManagerAbstractUniswap {
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

    PositionManagerAbstractUniswap_init(
      0xC36442b4a4522E871399CD717aBDD847Ab11FE88,
      0xE592427A0AEce92De3Edee1F18E0157C05861564,
      _protocolConfig,
      _assetManagerConfig,
      _accessController
    );
  }
}
