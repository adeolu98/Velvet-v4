# Vulnerability Report: Missing Balance Return in Zero Amount Swap

## Description
The `PositionManagerAlgebraAbstract` contract's `_swapTokensForAmount` function fails to return updated token balances when handling zero amount swaps (i.e., when `_params._amountIn = 0`). This occurs even though the balances are calculated internally during the verification process. This can lead to incorrect balance reporting and potential issues in dependent contract logic.

## Vulnerability Details
```solidity
function _swapTokensForAmount(
    WrapperFunctionParameters.SwapParams memory _params
) internal override returns (uint256 balance0, uint256 balance1) {
    // Swap tokens to the token0 or token1 pool ratio
    if (_params._amountIn > 0) {
        (balance0, balance1) = _swapTokenToToken(_params);
    } else {
        //@audit balance0 and balance1 are not returned here
        (uint128 tokensOwed0, uint128 tokensOwed1) = _getTokensOwed(
            _params._tokenId
        );
        SwapVerificationLibraryAlgebra.verifyZeroSwapAmountForReinvestFees(
            protocolConfig,
            _params,
            address(uniswapV3PositionManager),
            tokensOwed0,
            tokensOwed1
        );
    }
}
```

The issue arises because:
1. When `_params._amountIn = 0`, the function enters the else block
2. Inside `verifyZeroSwapAmountForReinvestFees()`, the function calls `calculateRatios()` which calculates and returns the current token balances
3. However, these balances are not captured and returned by `_swapTokensForAmount`
4. As a result, the function returns `(0, 0)` for `balance0` and `balance1`, even though there may be non-zero balances

## Impact
- **Incorrect Balance Reporting**: Functions relying on the returned balances will receive incorrect (zero) values, even when actual token balances exist in the contract.
- **Failed Reinvestment Logic**: If any reinvestment or rebalancing logic depends on these returned balances, it may fail or behave incorrectly.
- **Inconsistent State**: The contract's internal state becomes inconsistent with its reported values, potentially affecting dependent operations.

## Recommendation
Modify the `_swapTokensForAmount` function to properly return balances in both cases:

```solidity
function _swapTokensForAmount(
    WrapperFunctionParameters.SwapParams memory _params
) internal override returns (uint256 balance0, uint256 balance1) {
    if (_params._amountIn > 0) {
        (balance0, balance1) = _swapTokenToToken(_params);
    } else {
        (uint128 tokensOwed0, uint128 tokensOwed1) = _getTokensOwed(
            _params._tokenId
        );
        SwapVerificationLibraryAlgebra.verifyZeroSwapAmountForReinvestFees(
            protocolConfig,
            _params,
            address(uniswapV3PositionManager),
            tokensOwed0,
            tokensOwed1
        );
        // Return the actual balances
        balance0 = IERC20Upgradeable(_params._token0).balanceOf(address(this));
        balance1 = IERC20Upgradeable(_params._token1).balanceOf(address(this));
    }
}
```

## Proof of Concept
A test demonstrating this issue can be found in `test/foundry/SwapTokensForAmountZeroBalancePOC.t.sol`. The test shows that when calling `_swapTokensForAmount` with `_amountIn = 0`, the function returns zero balances even though there are actual token balances in the contract.
