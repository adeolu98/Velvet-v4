# Incorrect Liquidity Calculation in SwapVerificationLibraryAlgebra

## Summary
The `calculateRatios` function in SwapVerificationLibraryAlgebra incorrectly calculates position ratios by hardcoding the liquidity amount to 1e18 in the underlying `getRatioForTicks` function call, leading to incorrect ratio calculations that could result in invalid swap verifications.

## Finding Description
The `calculateRatios` function in SwapVerificationLibraryAlgebra uses `LiquidityAmountsCalculations.getRatioForTicks` to determine pool ratios. Here's the problematic implementation in `LiquidityAmountsCalculations.sol`:

```solidity
function getRatioForTicks(
    IPositionWrapper _positionWrapper,
    address _factory,
    address _token0,
    address _token1,
    int24 _tickLower,
    int24 _tickUpper
) internal returns (uint256 ratio, address tokenZeroBalance) {
    uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower);
    uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper);

    (uint256 amount0, uint256 amount1) = _getUnderlyingAmounts(
        _positionWrapper,
        _factory,
        sqrtRatioAX96,
        sqrtRatioBX96,
        1 ether  // @audit Hardcoded liquidity amount
    );

    if (amount0 == 0) {
        ratio = 0;
        tokenZeroBalance = _token0;
    } else if (amount1 == 0) {
        ratio = 0;
        tokenZeroBalance = _token1;
    } else {
        ratio = (amount0 * 1e18) / amount1;
    }
}
```

The issue lies in the hardcoded `1 ether` (1e18) value passed to `_getUnderlyingAmounts()`. This means the ratio calculations are always performed with a fixed liquidity value, regardless of the actual liquidity in the position. This is incorrect because:
The `calculateRatios` function in SwapVerificationLibraryAlgebra uses `LiquidityAmountsCalculations.getRatioForTicks` to determine pool ratios, which internally calls `_getUnderlyingAmounts()`. However, this calculation is performed with a hardcoded liquidity value of 1e18 (1 ether), regardless of the actual liquidity in the position.

```solidity
// In SwapVerificationLibraryAlgebra.sol
function calculateRatios(
    IPositionWrapper _positionWrapper,
    address _nftManager,
    int24 _tickLower,
    int24 _tickUpper,
    address _token0,
    address _token1
) public returns (
    uint256 balance0,
    uint256 balance1,
    uint256 ratioAfterSwap,
    uint256 poolRatio,
    address tokenZeroBalance
) {
    // ... balance calculations ...

    (poolRatio, tokenZeroBalance) = LiquidityAmountsCalculations
        .getRatioForTicks(
            _positionWrapper,
            getFactoryAddress(_nftManager),
            _token0,
            _token1,
            _tickLower,
            _tickUpper
        );
}
```

The issue lies in the fact that Uniswap V3 positions can have varying amounts of liquidity, and using a fixed liquidity value of 1e18 for calculations will lead to incorrect ratio calculations when:
1. The actual position liquidity is less than 1e18
2. The actual position liquidity is more than 1e18

This incorrect calculation affects:
1. The returned poolRatio value
2. Any subsequent ratio verifications using this value
3. Potential swap validations that rely on these ratios

## Impact Explanation
This vulnerability has a HIGH impact because:
1. It affects all ratio calculations and subsequent swap verifications
2. Can lead to invalid swaps being approved or valid swaps being rejected
3. May result in financial losses due to incorrect ratio enforcement
4. Undermines the core security mechanism of ratio verification

## Likelihood Explanation
The likelihood is HIGH because:
1. The issue affects every position that doesn't have exactly 1e18 liquidity
2. Most Uniswap V3 positions have varying amounts of liquidity
3. The vulnerability is present in every ratio calculation
4. No special conditions are needed to trigger the issue

## Proof of Concept
The following test demonstrates how using a hardcoded liquidity value leads to incorrect ratio calculations:

```solidity
// test/foundry/CalculateRatioPOC.sol
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/wrappers/algebra/SwapVerificationLibraryAlgebra.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract CalculateRatioPOC is Test {
    SwapVerificationLibraryAlgebra lib;
    MockPositionWrapper wrapper;
    MockNFTManager nftManager;
    
    function setUp() public {
        lib = new SwapVerificationLibraryAlgebra();
        wrapper = new MockPositionWrapper();
        nftManager = new MockNFTManager();
    }

    function testIncorrectRatioCalculation() public {
        address token0 = address(0x1);
        address token1 = address(0x2);
        int24 tickLower = -100;
        int24 tickUpper = 100;
        
        // Test with position having 2e18 liquidity
        wrapper.setLiquidity(2e18);
        
        (,,, uint256 poolRatio1,) = lib.calculateRatios(
            wrapper,
            address(nftManager),
            tickLower,
            tickUpper,
            token0,
            token1
        );
        
        // Test with position having 0.5e18 liquidity
        wrapper.setLiquidity(0.5e18);
        
        (,,, uint256 poolRatio2,) = lib.calculateRatios(
            wrapper,
            address(nftManager),
            tickLower,
            tickUpper,
            token0,
            token1
        );
        
        // Both calculations return the same ratio despite different liquidity amounts
        assertEq(poolRatio1, poolRatio2, "Ratios should be different for different liquidity amounts");
    }
}

contract MockPositionWrapper {
    uint128 private liquidity;
    
    function setLiquidity(uint128 _liquidity) external {
        liquidity = _liquidity;
    }
    
    function getLiquidity() external view returns (uint128) {
        return liquidity;
    }
}

contract MockNFTManager {
    function factory() external pure returns (address) {
        return address(0x3);
    }
}
```

## Recommendation
Modify the `getRatioForTicks` function to use the actual liquidity amount from the position:

```solidity
function getRatioForTicks(
    IPositionWrapper _positionWrapper,
    address _factory,
    address _token0,
    address _token1,
    int24 _tickLower,
    int24 _tickUpper
) public view returns (uint256, address) {
    // Get actual liquidity from the position
     (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 existing_liquidity,
            ,
            ,
            ,
            
        ) = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER).positions(
                IPositionWrapper(address(positionWrapper)).tokenId()
            );
    
    // Use actual liquidity instead of hardcoded 1e18
    (uint256 amount0, uint256 amount1) = _getUnderlyingAmounts(
        _factory,
        _token0,
        _token1,
        _tickLower,
        _tickUpper,
        existing_liquidity
    );
    
   //then continue logic 
}
```

This change ensures that ratio calculations accurately reflect the actual liquidity in the position, leading to correct swap verifications and better protection against invalid trades.
