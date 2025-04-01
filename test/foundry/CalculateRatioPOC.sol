// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/wrappers/uniswapV3/SwapVerificationLibraryUniswap.sol";
import "../../contracts/wrappers/abstract/PositionWrapper.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract CalculateRatioPOC is Test {
    address constant UNISWAP_V3_POSITION_MANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address pool = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8; //usdc pool
    //address pool = 0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36; //usdt pool
    // USDC/WETH 0.3% pool parameters
    uint24 constant FEE = 3000;
    int24 constant TICK_LOWER = -76650;
    int24 constant TICK_UPPER = -76440;
    address user = makeAddr("user");

    PositionWrapper positionWrapper;
    ProxyAdmin admin;

    function setUp() public {
        // Deploy implementation and proxy admin
        PositionWrapper implementation = new PositionWrapper();
        admin = new ProxyAdmin();

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(
            PositionWrapper.init.selector,
            UNISWAP_V3_POSITION_MANAGER,
            USDC,
            WETH,
            "USDC-WETH-LP",
            "LP"
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(admin),
            initData
        );

        // Get position wrapper interface
        positionWrapper = PositionWrapper(address(proxy));

        // Set initial parameters
        positionWrapper.setIntitialParameters(FEE, TICK_LOWER, TICK_UPPER);

        // Create a new position in Uniswap V3
        (uint256 tokenId, , ) = createUniswapPosition();
        positionWrapper.setTokenId(tokenId);
    }

    uint amount0Taken;
    uint amount1Taken;
    uint userToken0Balance;
    uint userToken1Balance;

    function createUniswapPosition()
        internal
        returns (
            uint256 tokenId,
            uint amountOfToken0Taken,
            uint amountOfToken1Taken
        )
    {
        // Approve tokens
        deal(USDC, user, 25_000 * 1e6);
        deal(WETH, user, 10 ether);

        vm.startPrank(user);
        IERC20Upgradeable(USDC).approve(
            UNISWAP_V3_POSITION_MANAGER,
            type(uint256).max
        );
        IERC20Upgradeable(WETH).approve(
            UNISWAP_V3_POSITION_MANAGER,
            type(uint256).max
        );

        // Get tick spacing
        int24 tickSpacing = IUniswapV3Pool(pool).tickSpacing();

        (, int24 curTick, , , , , ) = IUniswapV3Pool(pool).slot0();
        curTick = curTick - (curTick % tickSpacing);
        int24 lowerTick = curTick - (tickSpacing * 2);
        int24 upperTick = curTick + (tickSpacing * 2);
        require(curTick % tickSpacing == 0, "tick error");

        userToken0Balance = IERC20(USDC).balanceOf(user);
        userToken1Balance = IERC20(WETH).balanceOf(user);

        // Mint new position
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: USDC,
                token1: WETH,
                fee: FEE,
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: userToken0Balance,
                amount1Desired: userToken1Balance,
                amount0Min: 0,
                amount1Min: 0,
                recipient: user,
                deadline: block.timestamp + 30 minutes
            });

        (
            tokenId,
            ,
            amountOfToken0Taken,
            amountOfToken1Taken
        ) = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER).mint(
            params
        );

        //the amount of token0 and token1 taken should roughly equal to
        //the amount recalculated later in the test with LiquidityAmountsCalculations._getUnderlyingAmounts
        //if we use the actual liquidity amount.

        amount0Taken = amountOfToken0Taken;
        amount1Taken = amountOfToken1Taken;

        console.log("amount supplied to create position (USDC):", amount0Taken);
        console.log("amount supplied to create position (weth):", amount1Taken);
        console.log("");

        vm.stopPrank();
    }

    function testCalculateRatios() public {
        (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 existing_liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER).positions(
                IPositionWrapper(address(positionWrapper)).tokenId()
            );

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        (uint256 amount0, uint256 amount1) = LiquidityAmountsCalculations
            ._getUnderlyingAmounts(
                IPositionWrapper(address(positionWrapper)),
                INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER)
                    .factory(),
                sqrtRatioAX96,
                sqrtRatioBX96,
                existing_liquidity
            );

        (
            uint256 amount0IncorrectLiquidity,
            uint256 amount1IncorrectLiquidity
        ) = LiquidityAmountsCalculations._getUnderlyingAmounts(
                IPositionWrapper(address(positionWrapper)),
                INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER)
                    .factory(),
                sqrtRatioAX96,
                sqrtRatioBX96,
                1 ether
            );

        assertNotEq(amount0, amount0IncorrectLiquidity);
        assertNotEq(amount1, amount1IncorrectLiquidity);

        // Log results
        console.log(
            "Amount0 recalculated when correct liquidity value is used (USDC):",
            amount0
        );
        console.log(
            "Amount1 recalculated when correct liquidity value is used (weth):",
            amount1
        );
        console.log("please note that while values recalculated as amount 0 and amount 1 may be slightly different from actual amount supplied, the total value in USD of both token amounts recalulted remains the same as supplied");
        console.log("");
        console.log(
            "Amount0 when incorrect liquidity (1e18) used as liquidity for calculation (USDC):",
            amount0IncorrectLiquidity
        );
        console.log(
            "Amount1 when incorrect liquidity (1e18) used as liquidity for calculation (weth):",
            amount1IncorrectLiquidity
        );
        console.log("these amounts calaculated with existing_liquidity as 1 ether are inflated as they are way more than the amount of tokens the user supplied or ever had it its balance");

        assertGt(amount0IncorrectLiquidity, userToken0Balance);
        assertGt(amount1IncorrectLiquidity, userToken1Balance);
        //this simply means that there has been a wrong calc for amount0IncorrectLiquidity and amount1IncorrectLiquidity
        //because how can the calc for when existing liquidity is 1 ether  return a value that is more than the tokens user supplied?
        //even more than the user ever held in its balance?
    }
}
