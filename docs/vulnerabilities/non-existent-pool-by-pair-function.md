# Non-existent poolByPair Function Call in PositionManagerAlgebraAbstract

## Severity: High

## Description
The `PositionManagerAlgebraAbstract` contract attempts to call a non-existent function `poolByPair` on the Uniswap V3 factory contract. This function call is used to retrieve the pool address for a given token pair, but `poolByPair` is not a function that exists in the Uniswap V3 factory interface. Instead, Uniswap V3 uses `getPool` for this functionality.

## Impact
- The contract will fail to execute any operations that rely on retrieving pool addresses
- This affects core functionality like swapping tokens and managing liquidity positions
- All transactions that involve pool interactions will revert
- Users will be unable to perform essential operations like:
  - Creating new positions
  - Swapping tokens
  - Managing liquidity

## Proof of Concept
```solidity
// In PositionManagerAlgebraAbstract.sol
IPool pool = IPool(factory.poolByPair(_token0, _token1)); // This line will revert

// Correct Uniswap V3 Factory interface function is:
function getPool(
    address tokenA,
    address tokenB,
    uint24 fee
) external view returns (address pool);
```

## Recommendation
Replace the `poolByPair` call with the correct Uniswap V3 factory function `getPool`. Note that `getPool` requires an additional `fee` parameter:

```solidity
// Before
IPool pool = IPool(factory.poolByPair(_token0, _token1));

// After
IPool pool = IPool(factory.getPool(_token0, _token1, fee));
```

Additionally:
1. Add a fee parameter to functions that need to interact with specific pools
2. Consider storing the fee tier as part of the position configuration
3. Validate that the returned pool address is not zero before attempting to use it

## References
- [Uniswap V3 Factory Interface](https://docs.uniswap.org/contracts/v3/reference/core/interfaces/IUniswapV3Factory)
- [Uniswap V3 Pool Interface](https://docs.uniswap.org/contracts/v3/reference/core/interfaces/IUniswapV3Pool)
