// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {PositionManagerAbstractUniswap} from "../uniswapV3/PositionManagerAbstractUniswap.sol";

/**
 * @title PositionManager
 * @dev Concrete implementation of the PositionManagerAbstract contract.
 * This contract inherits all functionalities from PositionManagerAbstract and serves as the final implementation.
 * It includes a placeholder for adding custom logic specific to Pancakeswap (staking, boost).
 */
contract PositionManagerPancakeSwap is PositionManagerAbstractUniswap {
  //@todo add custom logic for Pancakeswap (staking, boost)
}
