# Missing Slippage Protection in UniswapV3SwapHandler

## Summary
The `swapTokenToToken` function in UniswapV3SwapHandler lacks slippage protection by setting `amountOutMinimum` to 0, exposing users to potential sandwich attacks and excessive slippage losses.

## Finding Description
The `UniswapV3SwapHandler.swapTokenToToken` function is designed to facilitate token swaps through Uniswap V3. However, it deliberately disables slippage protection by setting `amountOutMinimum: 0` in the `ExactInputSingleParams` struct when calling Uniswap's router.

```solidity
ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
  .ExactInputSingleParams({
    tokenIn: tokenIn,
    tokenOut: tokenOut,
    fee: poolFee,
    recipient: msg.sender,
    deadline: block.timestamp,
    amountIn: amountIn,
    amountOutMinimum: 0, // mediumm: No slippage protection
    sqrtPriceLimitX96: 0
  });
```

This means that any swap through this function will be executed regardless of the output amount, even if the user receives significantly fewer tokens than expected due to:
1. Front-running attacks (sandwich attacks)
2. High market volatility
3. Manipulated pool prices
4. MEV bot exploitation

## Impact Explanation
This vulnerability has a medium impact because:
1. It can lead to direct financial losses for users
2. The losses can be substantial (potentially up to 100% of the swap value)
3. The issue affects all swaps performed through this contract
4. MEV bots can systematically exploit this vulnerability

## Likelihood Explanation
The likelihood is HIGH because:
1. MEV bots actively monitor and exploit unprotected swaps
2. DeFi protocols are prime targets for sandwich attacks
3. The vulnerability requires no special conditions to exploit
4. The issue is present in every swap transaction

## Proof of Concept
The following test demonstrates how the `swapTokenToToken` function allows trades that result in receiving zero tokens, which would be prevented with proper slippage protection:

- to run with foundryin the repo, 
1. run `npm i --save-dev @nomicfoundation/hardhat-foundry`
2. add `import "@nomicfoundation/hardhat-foundry";` to `hardhat.config.ts`
3. run `forge init --force`
4. add `optimizer=true` and `viaIR = true` to `foundry.toml`
5. run `forge clean && forge build && forge test --mt testSwapTokenToToken`

```solidity
// From test/foundry/UniswapV3SwapHandler.t.sol
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/wrappers/uniswapV3/UniswapV3SwapHandler.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract MockUniswapRouter {
    function exactInputSingle(
        ISwapRouter.ExactInputSingleParams memory params
    ) public payable returns (uint256 amountOut) {
        //this mock function in this mock uniswap router will always return 0 of tokens to the recipent
        //return of 0 amount of tokens back to recipient can happen in a DEX pool in severe cases of slippage loss or sandwiching
        ERC20(params.tokenOut).transfer(params.recipient, 0);
        amountOut = 0;
    }
}

contract UniswapV3SwapHandlerTest is Test {
    function testSwapTokenToToken() public {
        // Test parameters
        uint24 poolFee = 3000; // 0.3% fee tier
        uint256 amountIn = 1000 * 10 ** 18; // 1000 tokens

        // Perform the swap
        uint256 amountOut = swapHandler.swapTokenToToken(
            address(tokenA),
            address(tokenB),
            poolFee,
            amountIn
        );

        assertGt(amountIn, 0); //amount of token in is not 0
        assertEq(amountOut, 0, "Amount out should be 0"); //amount of token out after the swap is 0
    }
}
```

## Recommendation
Modify the `swapTokenToToken` function to include a `minAmountOut` parameter that is passed to the Uniswap router:

```solidity
function swapTokenToToken(
    address tokenIn,
    address tokenOut,
    uint24 poolFee,
    uint amountIn,
    uint minAmountOut  // Add minimum amount out parameter
) external returns (uint amountOut) {
    TransferHelper.safeTransferFrom(
        tokenIn,
        msg.sender,
        address(this),
        amountIn
    );
    TransferHelper.safeApprove(tokenIn, address(router), amountIn);

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut, // Use the provided minimum amount
            sqrtPriceLimitX96: 0
        });

    amountOut = router.exactInputSingle(params);
    require(amountOut >= minAmountOut, "Insufficient output amount");
}
```

This change ensures that users can specify their maximum acceptable slippage and protect themselves from sandwich attacks and unfavorable trades.
