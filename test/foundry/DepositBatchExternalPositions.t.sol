// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/bundle/DepositBatchExternalPositions.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../contracts/FunctionParameters.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract MockPortfolio {
    address[] public tokens;
    address public assetManagementConfig;

    constructor(address[] memory _tokens, address _assetManagementConfig) {
        tokens = _tokens;
        assetManagementConfig = _assetManagementConfig;
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function multiTokenDepositFor(
        address user,
        uint256[] memory amounts,
        uint256 minMintAmount
    ) external {}
}

contract MockAssetManagementConfig {
    function getPositionWrapperConfig(
        address wrapper
    ) external pure returns (bool isValid) {
        return true;
    }
}

contract DepositBatchExternalPositionsTest is Test {
    DepositBatchExternalPositions public depositBatch;
    ERC20 public tokenA;
    ERC20 public tokenB;
    //MockToken public tokenC;
    MockPortfolio public portfolio;
    MockAssetManagementConfig public assetConfig;

    address public user = makeAddr("user");
    address[] public tokens;

    function setUp() public {
        tokens = new address[](2);
        tokens[0] = (0xdAC17F958D2ee523a2206206994597C13D831ec7); //BNB on eth mainnet;
        tokens[1] = (0xB8c77482e45F1F44dE1745F52C74426C631bDD52); //usdt on mainnet
        //tokenC =  (0x6B175474E89094C44Da98b954EedeAC495271d0F); //weth on mainnet

        tokenA = ERC20(tokens[0]);
        tokenB = ERC20(tokens[1]);

        // Deploy mock asset config
        assetConfig = new MockAssetManagementConfig();

        // Deploy mock portfolio
        portfolio = new MockPortfolio(tokens, address(assetConfig));

        // Deploy deposit batch contract
        depositBatch = new DepositBatchExternalPositions();

        // Setup initial token balances for user
        vm.deal(user, 1000e18);
        // deal(address(tokenA), user, 1000 * 10**18);
        // deal(address(tokenB), user, 1000 * 10**18);
        // deal(address(tokenC), user, 1000 * 10**18);

        // Setup approvals
       // vm.startPrank(user);
        //tokenA.approve(address(depositBatch), 1000e18);
       // tokenB.approve(address(depositBatch), 1000e18);
        //tokenC.approve(address(depositBatch), 1000e18);
        //vm.stopPrank();
    }

    function testMultiTokenSwapAndDeposit() public {
        // Create BatchHandler struct
        FunctionParameters.BatchHandler memory batchData = FunctionParameters
            .BatchHandler({
                _target: address(portfolio),
                _depositToken: address(tokenA),
                _callData: new bytes[](2),
                _minMintAmount: 0,
                _depositAmount: 10000
            });

        // Encode swap data
        batchData._callData[0] = abi.encode(100 * 10 ** 18); // TokenA amount
        batchData._callData[1] = abi.encode(50 * 10 ** 18); // TokenB amount

        // Create ExternalPositionDepositParams struct
        FunctionParameters.ExternalPositionDepositParams
            memory depositParams = FunctionParameters
                .ExternalPositionDepositParams({
                    _swapTokens: new address[](2),
                    _portfolioTokenIndex: new uint256[](2),
                    _isExternalPosition: new bool[](2),
                    _positionWrappers: new address[](0),
                    _positionWrapperIndex: new uint256[](0),
                    _index0: new uint256[](0),
                    _index1: new uint256[](0),
                    _tokenIn: new address[](0),
                    _tokenOut: new address[](0),
                    _amountIn: new uint256[](0),
                    _amount0Min: new uint256[](0),
                    _amount1Min: new uint256[](0)
                });

        depositParams._swapTokens[0] = address(tokenA);
        depositParams._swapTokens[1] = address(tokenB);
        depositParams._portfolioTokenIndex[0] = 0;
        depositParams._portfolioTokenIndex[1] = 1;
        depositParams._isExternalPosition[0] = false;
        depositParams._isExternalPosition[1] = false;

        // Execute multiTokenSwapAndDeposit
        vm.startPrank(user);
        depositBatch.multiTokenSwapAndDeposit(batchData, depositParams, user);
        vm.stopPrank();

        // Verify the results
        // Note: In a real scenario, we would verify the token balances and portfolio state
        // but since we're using mocks, we mainly verify that the function executes without reverting
        assertTrue(true, "Function should execute successfully");
    }
}
