// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {PositionManagerAbstractUniswap} from "./PositionManagerAbstractUniswap.sol";

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
    PositionManagerAbstractUniswap_init(
      _protocolConfig,
      0xC36442b4a4522E871399CD717aBDD847Ab11FE88,
      _assetManagerConfig,
      _accessController
    );
  }
}
