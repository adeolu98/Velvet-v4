// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/wrappers/algebra/PositionManagerAlgebraAbstract.sol";
import "../../contracts/wrappers/algebra/ISwapRouter.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/wrappers/abstract/IPositionWrapper.sol";
import "../../contracts/wrappers/abstract/PositionWrapper.sol";

contract MockFactory {
    address public mockPool;

    constructor( address token0, address token1) {
        mockPool = address(new MockPool(token0, token1));
    }

    function poolByPair(address, address) external view returns (address) {
        return mockPool;
    }
}

contract MockPool {
    function slot0() external pure returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked) {
        return (1 << 96, 0, 0, 0, 0, 0, true); // Mock values
    }

    address public token0;
    address public token1;

constructor (address _token0, address _token1) {
    setTokens(_token0, _token1);
}

    function setTokens(address _token0, address _token1) internal {
        token0 = _token0;   
        token1 = _token1;
    }
}

contract MockNonfungiblePositionManager {
    uint256 private _nextTokenId = 1;
    address public factory;

    function setFactory(address _factory) public {
        factory = _factory;
    }

    function mint(INonfungiblePositionManager.MintParams calldata params)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        tokenId = _nextTokenId++;
        liquidity = 1e18;
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;
    }

    function positions(uint256)
        external
        pure
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        return (0, address(0), address(0), address(0), 0, 0, 0, 0, 0, 0, 0, 0);
    }

    function collect(INonfungiblePositionManager.CollectParams calldata)
        external
        pure
        returns (uint256 amount0, uint256 amount1)
    {
        return (0, 0);
    }
}

contract MockProtocolConfig  {
    mapping(address => bool) public enabledTokens;
    address public positionWrapperBaseImplementation;

    function setTokenEnabled(address token, bool enabled) external {
        enabledTokens[token] = enabled;
    }

    function isTokenEnabled(address token) external view returns (bool) {
        return enabledTokens[token];
    }

    function setPositionWrapperBaseImplementation(address impl) external {
        positionWrapperBaseImplementation = impl;
    }

    function protocolTreasury() external pure returns (address) {
        return address(1);
    }

    function protocolFee() external pure returns (uint256) {
        return 0;
    }

    function protocolFeeReceiver() external pure returns (address) {
        return address(1);
    }

    function protocolFeePct() external pure returns (uint256) {
        return 0;
    }

    function protocolPerformanceFee() external pure returns (uint256) {
        return 0;
    }

    function protocolPerformanceFeeReceiver() external pure returns (address) {
        return address(1);
    }

    function protocolPerformanceFeePct() external pure returns (uint256) {
        return 0;
    }

    function isProtocolPaused() external pure returns (bool) {
        return false;
    }
}

contract MockPositionWrapperImpl is PositionWrapper {
   
}

contract mockAccessController {
    function hasRole(bytes32, address) external pure returns (bool) {
        return true;
    }
}

contract MockAssetManagementConfig  {
    bool public tokenWhitelistingEnabled;
    mapping(address => bool) public whitelistedTokens;

    function setTokenWhitelistingEnabled(bool enabled) external {
        tokenWhitelistingEnabled = enabled;
    }

    function setTokenWhitelisted(address token, bool whitelisted) external {
        whitelistedTokens[token] = whitelisted;
    }

    function isAssetManager(address) external pure returns (bool) {
        return true;
    }

    function isAssetManagerWhitelisted(address) external pure returns (bool) {
        return true;
    }

    function whitelistedAssetManagers(uint256) external pure returns (address) {
        return address(0);
    }

    function getWhitelistedAssetManagerCount() external pure returns (uint256) {
        return 0;
    }
}

contract MockPositionManagerAlgebra is PositionManagerAbstractAlgebra {
    address public factory;

    function setFactory(address _factory) external {
        factory = _factory;
    }

    function init(    address _nonFungiblePositionManagerAddress,
        address _swapRouter,
        address _protocolConfig,
        address _assetManagerConfig,
        address _accessController) public initializer {
      
    PositionManagerAbstractAlgebra_init(
      _nonFungiblePositionManagerAddress,
      _swapRouter,
      _protocolConfig,
      _assetManagerConfig,
      _accessController
    );
}
}

contract CreateWrapperPositionPOC is Test {
    MockPositionManagerAlgebra positionManager;
    ERC1967Proxy proxy;
    address token0;
    address token1;
    address accessController;
    MockProtocolConfig protocolConfig;
    MockAssetManagementConfig assetManagementConfig;
    MockNonfungiblePositionManager uniswapV3PositionManager;
    address swapRouter;
    address positionWrapperImpl;
    MockFactory factory;

    function setUp() public {
        // Deploy mock dependencies
        protocolConfig = new MockProtocolConfig();
        assetManagementConfig = new MockAssetManagementConfig();
        accessController = address(new mockAccessController());
        uniswapV3PositionManager = new MockNonfungiblePositionManager();
   
        swapRouter = makeAddr("swapRouter");
        token0 = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; //usdc on arb
        token1 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; //weth on arb
             factory = new MockFactory(token0, token1);
       
        // Deploy mock position wrapper implementation
        positionWrapperImpl = address(new MockPositionWrapperImpl());

        // Configure mocks
        protocolConfig.setTokenEnabled(token0, true);
        protocolConfig.setTokenEnabled(token1, true);
        protocolConfig.setPositionWrapperBaseImplementation(positionWrapperImpl);
        assetManagementConfig.setTokenWhitelistingEnabled(true);
        assetManagementConfig.setTokenWhitelisted(token0, true);
        assetManagementConfig.setTokenWhitelisted(token1, true);

        // Deploy implementation
        MockPositionManagerAlgebra implementation = new MockPositionManagerAlgebra();

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(
            MockPositionManagerAlgebra.init.selector,
            address(uniswapV3PositionManager),
            swapRouter,
            address(protocolConfig),
            address(assetManagementConfig),
            accessController
        );

        proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        // Set up the position manager
        positionManager = MockPositionManagerAlgebra(address(proxy));
        
        // Set up factory in the position manager
        positionManager.setFactory(address(factory));

        // Set up factory in the uniswapV3PositionManager
        uniswapV3PositionManager.setFactory(address(factory));
        
    }

    function test_fillUpArray() public {
        for (uint256 index = 0; index < type(uint).max; index++) {
            testCreateNewWrapperPosition();
        }
        vm.expectRevert();
        testCreateNewWrapperPosition();
    }

    function testCreateNewWrapperPosition() internal {
        // Define position parameters
        string memory name = "Test Position";
        string memory symbol = "TP";
        int24 tickLower = -887220;  // Example tick range for 1% around current price
        int24 tickUpper = 887220;   // Adjust based on your needs
        
        // Create the wrapper position
        IPositionWrapper wrapper = positionManager.createNewWrapperPosition(
            token0,
            token1,
            name,
            symbol,
            tickLower,
            tickUpper
        ); //@audit u need to mock factory.poolByPair() function, also reserach what defi protocol algebra is and how it relates to this code
        
        // Verify the wrapper was created successfully
        assertTrue(address(wrapper) != address(0), "Wrapper creation failed");
        
        // Additional verification
        assertEq(wrapper.token0(), token0, "Incorrect token0");
        assertEq(wrapper.token1(), token1, "Incorrect token1");
        assertEq(wrapper.name(), name, "Incorrect name");
        assertEq(wrapper.symbol(), symbol, "Incorrect symbol");
    }
}
