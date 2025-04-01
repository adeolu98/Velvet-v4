// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/wrappers/algebra/PositionManagerAlgebraAbstract.sol";
import "../../contracts/wrappers/algebra/SwapVerificationLibraryAlgebra.sol";
import "../../contracts/wrappers/WrapperFunctionParameters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ISwapRouter} from "../../contracts/wrappers/algebra/ISwapRouter.sol";
import {INonfungiblePositionManager} from "../../contracts/wrappers/algebra/INonfungiblePositionManager.sol";
import {IPriceOracle} from "../../contracts/oracle/IPriceOracle.sol";
import {IProtocolConfig} from "../../contracts/config/protocol/IProtocolConfig.sol";
import {IAssetManagementConfig} from "../../contracts/config/assetManagement/IAssetManagementConfig.sol";
import {IAccessController} from "../../contracts/access/IAccessController.sol";

// Mock contracts needed for testing
contract MockPositionWrapper is Initializable {
    address public token0;
    address public token1;
    uint256 public tokenId;

    function initialize(
        address _token0,
        address _token1,
        uint256 _tokenId
    ) public initializer {
        token0 = _token0;
        token1 = _token1;
        tokenId = _tokenId;
    }
}

contract MockToken is IERC20 {
    mapping(address => uint256) private _balances;

    constructor(uint256 initialBalance) {
        _balances[msg.sender] = initialBalance;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
    }

    // Mock implementations of other IERC20 functions
    function allowance(
        address,
        address
    ) external pure override returns (uint256) {
        return type(uint256).max;
    }
    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }
    function totalSupply() external pure override returns (uint256) {
        return 0;
    }
}

// Mock contracts for initialization
contract MockNonfungiblePositionManager {
    function positions(
        uint256 tokenId
    )
        external
        pure
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        // Return mock values that will trigger the issue
        return (
            0, // nonce
            address(0), // operator
            address(0), // token0
            address(0), // token1
            0, // tickLower
            0, // tickUpper
            0, // liquidity
            0, // feeGrowthInside0LastX128
            0, // feeGrowthInside1LastX128
            1e6, // tokensOwed0 - set to MIN_REINVESTMENT_AMOUNT to trigger reinvestment
            1e6 // tokensOwed1 - set to MIN_REINVESTMENT_AMOUNT to trigger reinvestment
        );
    }

    // Mock implementations of other INonfungiblePositionManager functions
    function collect(
        INonfungiblePositionManager.CollectParams calldata
    ) external pure returns (uint256 amount0, uint256 amount1) {}
    function mint(
        INonfungiblePositionManager.MintParams calldata params
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {}
    function increaseLiquidity(
        INonfungiblePositionManager.IncreaseLiquidityParams calldata params
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {}
    function decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata params
    ) external returns (uint256 amount0, uint256 amount1) {}
    function burn(uint256 tokenId) external {}
}

contract MockProtocolConfig {
    function priceOracle() external pure returns (IPriceOracle) {
        return IPriceOracle(address(0));
    }
    function assetManager() external pure returns (address) {
        return address(1);
    }
    function feeReceiver() external pure returns (address) {
        return address(2);
    }
    function performanceFee() external pure returns (uint256) {
        return 0;
    }
    function managementFee() external pure returns (uint256) {
        return 0;
    }
    function withdrawalFee() external pure returns (uint256) {
        return 0;
    }
}

contract MockAssetManagementConfig {
    function getAssetConfig(
        address
    ) external pure returns (uint256, uint256, uint256, uint256) {
        return (0, 0, 0, 0);
    }
}

contract MockAccessController {
    function hasRole(bytes32, address) external pure returns (bool) {
        return true;
    }
}

contract MockSwapRouter {
    function exactInputSingle(
        ISwapRouter.ExactInputSingleParams calldata
    ) external pure returns (uint256) {
        return 0;
    }
}

contract TestPositionManager is PositionManagerAbstractAlgebra {
    function initialize(
        address _nonFungiblePositionManagerAddress,
        address _swapRouter,
        address _protocolConfig,
        address _assetManagerConfig,
        address _accessController
    ) public initializer {
        PositionManagerAbstractAlgebra_init(
            _nonFungiblePositionManagerAddress,
            _swapRouter,
            _protocolConfig,
            _assetManagerConfig,
            _accessController
        );
    }

    // Make internal functions public for testing
    function publicSwapTokensForAmount(
        WrapperFunctionParameters.SwapParams memory _params
    ) public returns (uint256 balance0, uint256 balance1) {
        return _swapTokensForAmount(_params);
    }
}

contract SwapTokensForAmountZeroBalancePOC is Test {
    ProxyAdmin public proxyAdmin;
    address public positionManagerImplementation;
    address public positionWrapperImplementation;

    // Mock contracts for initialization
    MockNonfungiblePositionManager public nonfungiblePositionManager;
    MockProtocolConfig public protocolConfig;
    MockAssetManagementConfig public assetManagementConfig;
    MockAccessController public accessController;
    MockSwapRouter public swapRouter;
    TestPositionManager public positionManager;
    MockToken public token0;
    MockToken public token1;
    MockPositionWrapper public positionWrapper;

    function setUp() public {
        // Setup proxy admin
        proxyAdmin = new ProxyAdmin();

        // Setup mock tokens
        token0 = new MockToken(0);
        token1 = new MockToken(0);

        // Deploy implementations
        positionWrapperImplementation = address(new MockPositionWrapper());
        positionManagerImplementation = address(new TestPositionManager());

        // Deploy proxies
        bytes memory positionWrapperData = abi.encodeWithSelector(
            MockPositionWrapper.initialize.selector,
            address(token0),
            address(token1),
            1 // tokenId
        );

        TransparentUpgradeableProxy positionWrapperProxy = new TransparentUpgradeableProxy(
                positionWrapperImplementation,
                address(proxyAdmin),
                positionWrapperData
            );
        positionWrapper = MockPositionWrapper(address(positionWrapperProxy));

        // Deploy mock contracts for initialization
        nonfungiblePositionManager = new MockNonfungiblePositionManager();
        protocolConfig = new MockProtocolConfig();
        assetManagementConfig = new MockAssetManagementConfig();
        accessController = new MockAccessController();
        swapRouter = new MockSwapRouter();

        // Deploy position manager proxy with initialization
        bytes memory positionManagerData = abi.encodeWithSelector(
            TestPositionManager.initialize.selector,
            address(nonfungiblePositionManager), // Mock NFT position manager
            address(swapRouter),
            address(protocolConfig),
            address(assetManagementConfig),
            address(accessController)
        );

        TransparentUpgradeableProxy positionManagerProxy = new TransparentUpgradeableProxy(
                positionManagerImplementation,
                address(proxyAdmin),
                positionManagerData
            );
        positionManager = TestPositionManager(address(positionManagerProxy));

        // Mint and transfer tokens to the position manager
        token0.mint(address(positionManager), 1e18); // 1 token
        token1.mint(address(positionManager), 2e18); // 2 tokens
    }

    function testZeroAmountInReturnsZeroBalances() public {
        // Create swap params with zero amountIn
        WrapperFunctionParameters.SwapParams
            memory params = WrapperFunctionParameters.SwapParams({
                _positionWrapper: IPositionWrapper(address(positionWrapper)),
                _tokenId: 1, // From positionWrapper initialization
                _amountIn: 0, // Key parameter - setting to 0 to force the code to execute the else block
                _token0: address(token0),
                _token1: address(token1),
                _tokenIn: address(token0),
                _tokenOut: address(token1),
                _tickLower: 0,
                _tickUpper: 0
            });

        // Perform the swap
        (uint256 balance0, uint256 balance1) = positionManager
            .publicSwapTokensForAmount(params);

        // Assert that balances are incorrectly reported as 0
        // even though the mock tokens have non-zero balances
        assertEq(
            balance0,
            0,
            "Balance0 should be 0 due to missing return values"
        );
        assertEq(
            balance1,
            0,
            "Balance1 should be 0 due to missing return values"
        );

        // Prove that actual token balances in the position manager are non-zero
        assertEq(
            token0.balanceOf(address(positionManager)),
            1e18,
            "Actual token0 balance in PositionManager should be 1e18"
        );
        assertEq(
            token1.balanceOf(address(positionManager)),
            2e18,
            "Actual token1 balance in PositionManager should be 2e18"
        );
    }
}
