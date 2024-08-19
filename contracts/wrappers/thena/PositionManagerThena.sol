// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {PositionManagerAbstractAlgebra} from "../algebra/PositionManagerAlgebraAbstract.sol";

/**
 * @title PositionManager
 * @dev Concrete implementation of the PositionManagerAbstract contract.
 * This contract inherits all functionalities from PositionManagerAbstract and serves as the final implementation.
 */
contract PositionManagerThena is PositionManagerAbstractAlgebra {
  function init(
    address _protocolConfig,
    address _assetManagerConfig,
    address _accessController
  ) external initializer {
    PositionManagerAbstractAlgebra_init(
      0xa51ADb08Cbe6Ae398046A23bec013979816B77Ab,
      _protocolConfig,
      _assetManagerConfig,
      _accessController
    );
  }
}
