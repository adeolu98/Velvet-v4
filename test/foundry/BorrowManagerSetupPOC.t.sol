// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/PortfolioFactory.sol";
import "../../contracts/core/Portfolio.sol";
import "../../contracts/core/management/BorrowManager.sol";
import "../../contracts/config/protocol/ProtocolConfig.sol";
import "../../contracts/config/assetManagement/AssetManagementConfig.sol";
import "../../contracts/access/AccessController.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../contracts/core/interfaces/ITokenExclusionManager.sol";
import "../../contracts/rebalance/IRebalancing.sol";
import "../../contracts/fee/IFeeModule.sol";

// Mock contracts for Gnosis Safe components
contract MockGnosisSafe {
    mapping(address => bool) public modules;
    address[] public owners;
    uint256 public threshold;

    function setup(
        address[] memory _owners,
        uint256 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        owners = _owners;
        threshold = _threshold;
        // Simulate the execution of the multisend action
        if (to != address(0) && data.length > 0) {
            // This would normally execute the multiSend function
            // which would enable the module
        }
    }

    function enableModule(address module) external {
        modules[module] = true;
    }

    function isModuleEnabled(address module) external view returns (bool) {
        return true;
    }
}

contract MockGnosisSafeProxyFactory {
    function createProxy(
        address singleton,
        bytes memory data
    ) external returns (address proxy) {
        // Create a new MockGnosisSafe instance
        MockGnosisSafe safe = new MockGnosisSafe();
        return address(safe);
    }
}

contract MockMultiSend {
    function multiSend(bytes memory transactions) external {
        // This would normally execute multiple transactions in a batch
        // For our test, we don't need to do anything here
    }
}

contract MockVelvetSafeModule {
    address public safe;
    address public owner;
    address public multisendLibrary;

    function setUp(bytes memory initParams) external {
        (address _safe, address _owner, address _multisendLibrary) = abi.decode(
            initParams,
            (address, address, address)
        );
        safe = _safe;
        owner = _owner;
        multisendLibrary = _multisendLibrary;
    }
}

contract MockRebalancing {
    address public portfolio;
    address public accessController;
    address public borrowManager;

    function init(
        address _portfolio,
        address _accessController,
        address _borrowManager
    ) external {
        portfolio = _portfolio;
        accessController = _accessController;
        borrowManager = _borrowManager;
    }

    function rebalance(
        address[] calldata tokens,
        uint256[] calldata targetWeights,
        uint256 slippage
    ) external {}

    function rebalanceWithSwaps(
        address[] calldata tokens,
        uint256[] calldata targetWeights,
        uint256 slippage,
        bytes[] calldata swapData
    ) external {}
}

contract MockFeeModule {
    address public portfolio;
    address public assetManagementConfig;
    address public protocolConfig;
    address public accessController;

    function init(
        address _portfolio,
        address _assetManagementConfig,
        address _protocolConfig,
        address _accessController
    ) external {
        portfolio = _portfolio;
        assetManagementConfig = _assetManagementConfig;
        protocolConfig = _protocolConfig;
        accessController = _accessController;
    }

    function collectManagementFee() external {}

    function collectPerformanceFee() external {}

    function collectEntryFee(uint256 amount) external returns (uint256) {
        return amount;
    }

    function collectExitFee(uint256 amount) external returns (uint256) {
        return amount;
    }
}

contract MockTokenRemovalVault {
    function init(address _token) external {}
}

contract MockTokenExclusionManager {
    address public accessController;
    address public protocolConfig;
    address public baseTokenRemovalVaultImplementation;
    uint256 public currentSnapshotId;

    function init(
        address _accessController,
        address _protocolConfig,
        address _baseTokenRemovalVaultImplementation
    ) external {
        accessController = _accessController;
        protocolConfig = _protocolConfig;
        baseTokenRemovalVaultImplementation = _baseTokenRemovalVaultImplementation;
    }

    function snapshot() external returns (uint256) {
        currentSnapshotId++;
        return currentSnapshotId;
    }

    function _currentSnapshotId() external view returns (uint256) {
        return currentSnapshotId;
    }

    function claimRemovedTokens(
        address user,
        uint256 startId,
        uint256 endId
    ) external {}

    function setUserRecord(address _user, uint256 _userBalance) external {}

    function setTokenAndSupplyRecord(
        uint256 _snapShotId,
        address _tokenRemoved,
        address _vault,
        uint256 _totalSupply
    ) external {}

    function claimTokenAtId(address user, uint256 id) external {}

    function getDataAtId(
        address user,
        uint256 id
    ) external view returns (bool, uint256) {
        return (false, 0);
    }

    function userRecord(
        address user,
        uint256 snapshotId
    )
        external
        view
        returns (uint256 portfolioBalance, bool hasInteractedWithId)
    {
        return (0, false);
    }

    function deployTokenRemovalVault() external returns (address) {
        return address(0);
    }

    function removedToken(
        uint256 id
    )
        external
        view
        returns (address token, address vault, uint256 totalSupply)
    {
        return (address(0), address(0), 0);
    }
}

contract BorrowManagerSetupPOC is Test {
    PortfolioFactory portfolioFactory;
    Portfolio portfolio;
    ProtocolConfig protocolConfig;
    AssetManagementConfig assetManagementConfig;
    AccessController accessController;
    address rebalancing;
    address feeModule;
    BorrowManager borrowManager;
    address vaultAddress;
    address tokenExclusionManager;
    address user;

    // Implementation contracts
    BorrowManager borrowManagerImpl;
    Portfolio portfolioImpl;
    address tokenExclusionManagerImpl;
    address rebalancingImpl;
    address feeModuleImpl;
    address tokenRemovalVaultImpl;
    address velvetGnosisSafeModuleImpl;

    function setUp() public {
        // Setup addresses
        vaultAddress = makeAddr("vault");
        tokenExclusionManager = makeAddr("tokenExclusionManager");
        rebalancing = makeAddr("rebalancing");
        feeModule = makeAddr("feeModule");
        user = makeAddr("user");
        address velvetTreasury = makeAddr("velvetTreasury");
        address assetManagerTreasury = makeAddr("assetManagerTreasury");
        address oracle = makeAddr("oracle");
        address positionWrapperBase = makeAddr("positionWrapperBase");

        // Deploy Gnosis Safe mock contracts
        MockGnosisSafe gnosisSafeSingleton = new MockGnosisSafe();
        MockGnosisSafeProxyFactory gnosisSafeProxyFactory = new MockGnosisSafeProxyFactory();
        MockMultiSend gnosisMultisendLibrary = new MockMultiSend();
        MockVelvetSafeModule velvetSafeModuleImpl = new MockVelvetSafeModule();

        // Deploy AccessController directly (it doesn't use initializer pattern)
        accessController = new AccessController();

        // Deploy implementation contracts
        ProtocolConfig protocolConfigImpl = new ProtocolConfig();
        AssetManagementConfig assetManagementConfigImpl = new AssetManagementConfig();
        borrowManagerImpl = new BorrowManager();
        portfolioImpl = new Portfolio();

        // Set implementation contracts
        MockTokenExclusionManager mockTokenExclusionManager = new MockTokenExclusionManager();
        tokenExclusionManagerImpl = address(mockTokenExclusionManager);

        MockRebalancing mockRebalancing = new MockRebalancing();
        rebalancingImpl = address(mockRebalancing);

        MockFeeModule mockFeeModule = new MockFeeModule();
        feeModuleImpl = address(mockFeeModule);

        MockTokenRemovalVault mockTokenRemovalVault = new MockTokenRemovalVault();
        tokenRemovalVaultImpl = address(mockTokenRemovalVault);
        velvetGnosisSafeModuleImpl = address(velvetSafeModuleImpl); // Using the actual mock for VelvetSafeModule

        // Deploy ProtocolConfig proxy
        bytes memory protocolConfigData = abi.encodeWithSelector(
            ProtocolConfig.initialize.selector,
            velvetTreasury,
            oracle,
            positionWrapperBase
        );

        ERC1967Proxy protocolConfigProxy = new ERC1967Proxy(
            address(protocolConfigImpl),
            protocolConfigData
        );
        protocolConfig = ProtocolConfig(address(protocolConfigProxy));

        // Deploy AssetManagementConfig proxy
        FunctionParameters.AssetManagementConfigInitData
            memory assetManagementInitData = FunctionParameters
                .AssetManagementConfigInitData({
                    _managementFee: 100, // 1%
                    _performanceFee: 1000, // 10%
                    _entryFee: 0,
                    _exitFee: 0,
                    _initialPortfolioAmount: 1000 * 10 ** 18,
                    _minPortfolioTokenHoldingAmount: 1 * 10 ** 18,
                    _protocolConfig: address(protocolConfig),
                    _accessController: address(accessController),
                    _feeModule: feeModule,
                    _assetManagerTreasury: assetManagerTreasury,
                    _basePositionManager: makeAddr("basePositionManager"),
                    _nftManager: makeAddr("nftManager"),
                    _swapRouterV3: makeAddr("swapRouterV3"),
                    _whitelistedTokens: new address[](0),
                    _publicPortfolio: true,
                    _transferable: true,
                    _transferableToPublic: true,
                    _whitelistTokens: false,
                    _externalPositionManagementWhitelisted: false
                });

        bytes memory assetManagementConfigData = abi.encodeWithSelector(
            AssetManagementConfig.init.selector,
            assetManagementInitData
        );

        ERC1967Proxy assetManagementConfigProxy = new ERC1967Proxy(
            address(assetManagementConfigImpl),
            assetManagementConfigData
        );
        assetManagementConfig = AssetManagementConfig(
            address(assetManagementConfigProxy)
        );

        // Deploy BorrowManager proxy
        bytes memory borrowManagerData = abi.encodeWithSelector(
            BorrowManager.init.selector,
            vaultAddress,
            address(protocolConfig),
            address(0), // portfolio address will be set later
            address(accessController)
        );

        ERC1967Proxy borrowManagerProxy = new ERC1967Proxy(
            address(borrowManagerImpl),
            borrowManagerData
        );
        borrowManager = BorrowManager(address(borrowManagerProxy));

        // Deploy PortfolioFactory implementation
        PortfolioFactory portfolioFactoryImpl = new PortfolioFactory();

        // Create initialization data for PortfolioFactory
        FunctionParameters.PortfolioFactoryInitData
            memory portfolioFactoryInitData = FunctionParameters
                .PortfolioFactoryInitData({
                    _basePortfolioAddress: address(portfolioImpl),
                    _baseTokenExclusionManagerAddress: tokenExclusionManagerImpl,
                    _baseRebalancingAddres: rebalancingImpl,
                    _baseAssetManagementConfigAddress: address(
                        assetManagementConfigImpl
                    ),
                    _feeModuleImplementationAddress: feeModuleImpl,
                    _baseTokenRemovalVaultImplementation: tokenRemovalVaultImpl,
                    _baseVelvetGnosisSafeModuleAddress: velvetGnosisSafeModuleImpl,
                    _basePositionManager: makeAddr("positionManager"),
                    _baseBorrowManager: address(borrowManagerImpl),
                    _gnosisSingleton: address(gnosisSafeSingleton),
                    _gnosisFallbackLibrary: makeAddr("gnosisFallbackLibrary"),
                    _gnosisMultisendLibrary: address(gnosisMultisendLibrary),
                    _gnosisSafeProxyFactory: address(gnosisSafeProxyFactory),
                    _protocolConfig: address(protocolConfig)
                });

        // Deploy PortfolioFactory proxy
        bytes memory portfolioFactoryData = abi.encodeWithSelector(
            PortfolioFactory.initialize.selector,
            portfolioFactoryInitData
        );

        ERC1967Proxy portfolioFactoryProxy = new ERC1967Proxy(
            address(portfolioFactoryImpl),
            portfolioFactoryData
        );
        portfolioFactory = PortfolioFactory(address(portfolioFactoryProxy));

        // Grant PORTFOLIO_CREATOR role to user
        accessController.grantRole(keccak256("PORTFOLIO_CREATOR"), user);
    }

    function testIncorrectBorrowManagerSetup() public {
        // Switch to user context
        vm.startPrank(user);

        // Create whitelisted tokens array
        address[] memory whitelistedTokens = new address[](2);
        whitelistedTokens[0] = makeAddr("token1");
        whitelistedTokens[1] = makeAddr("token2");

        // user Create portfolio with creation init data
        FunctionParameters.PortfolioCreationInitData
            memory initData = FunctionParameters.PortfolioCreationInitData({
                _assetManagerTreasury: vaultAddress, // Using vault address as treasury
                _whitelistedTokens: whitelistedTokens,
                _managementFee: 100, // 1%
                _performanceFee: 1000, // 10%
                _entryFee: 0,
                _exitFee: 0,
                _initialPortfolioAmount: 1000 * 10 ** 18,
                _minPortfolioTokenHoldingAmount: 1 * 10 ** 18,
                _public: true,
                _transferable: true,
                _transferableToPublic: true,
                _whitelistTokens: false,
                _externalPositionManagementWhitelisted: false,
                _name: "Test Portfolio",
                _symbol: "TEST"
            });

        // Create a new portfolio using non-custodial function
        portfolioFactory.createPortfolioNonCustodial(initData);

        // Get the portfolio info from the portfolio list stored in mapping
        (
            address portfolioAddress,
            address tokenExclusionManager,
            address rebalancing,
            address owner,
            address borrowManager,
            address assetManagementConfig,
            address feeModule,
            address vaultAddress,
            address gnosisModule
        ) = portfolioFactory.PortfolioInfolList(0);
        Portfolio createdPortfolio = Portfolio(portfolioAddress);

        assertEq(borrowManager, user); // borrowManager should not be set to user, borrowManager is a proxy contract, user is not a contract
        assertNotEq(owner, user ); // owner should be set to the user, which is the caller of the createPortfolio function, but now, owner is actually the deployed borrowManager proxy contrract
        vm.stopPrank();
    }
}
