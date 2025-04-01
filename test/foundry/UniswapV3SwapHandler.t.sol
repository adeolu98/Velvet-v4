// SPDX-License-Identifier: BUSL-1.1
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
    UniswapV3SwapHandler public swapHandler;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public mockRouter;
    address public mockWETH;

    function setUp() public {
        // Deploy mock tokens
        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");

        // Set up mock addresses
        mockRouter = address(new MockUniswapRouter());
        mockWETH = makeAddr("WETH");

        // Deploy swap handler
        swapHandler = new UniswapV3SwapHandler(address(mockRouter), mockWETH);

        // Approve tokens for swapping
        tokenA.approve(address(swapHandler), type(uint256).max);
        tokenB.approve(address(swapHandler), type(uint256).max);
    }

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

        // Verify the output amount
        assertGt(amountIn, 0); //amount of token in is not 0

        assertEq(amountOut, 0, "Amount out should be 0"); //amount of token out after the swap is 0
    }
}
