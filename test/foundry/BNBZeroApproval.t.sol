// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/bundle/DepositBatchExternalPositions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/FunctionParameters.sol";

interface IBNB is IERC20 {
    function approve(address spender, uint256 value) external returns (bool);
}

contract MockPortfolio {
    address[] public tokens;
    
    constructor(address[] memory _tokens) {
        tokens = _tokens;
    }
    
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }
    
    function multiTokenDepositFor(address user, uint256[] memory amounts, uint256 minMintAmount) external {}
}

contract BNBZeroApprovalTest is Test {
    DepositBatchExternalPositions public depositBatch;
    MockPortfolio public portfolio;
    IBNB constant BNB = IBNB(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
    address[] tokens;
    address user = makeAddr("user");

    function setUp() public {
        
        // Setup tokens array with BNB
        tokens = new address[](1);
        tokens[0] = address(BNB);
        
        // Deploy mock portfolio and deposit batch contract
        portfolio = new MockPortfolio(tokens);
        depositBatch = new DepositBatchExternalPositions();
    }

    function testBNBZeroApprovalReverts() public {
        // Direct zero approval to BNB should revert
        vm.expectRevert();
        BNB.approve(address(1), 0);
    }

    function testDepositBatchRevertsDueToZeroApproval() public {
        // Create batch handler struct
        FunctionParameters.BatchHandler memory batchData = FunctionParameters
            .BatchHandler({
                _target: address(portfolio),
                _depositToken: address(BNB),
                _callData: new bytes[](1),
                _minMintAmount: 0,
                _depositAmount: 100
            });

        // Encode deposit amount
        batchData._callData[0] = abi.encode(1 ether);

        // Create deposit params
        FunctionParameters.ExternalPositionDepositParams
            memory depositParams = FunctionParameters.ExternalPositionDepositParams({
                _swapTokens: new address[](1),
                _portfolioTokenIndex: new uint256[](1),
                _isExternalPosition: new bool[](1),
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

        depositParams._swapTokens[0] = address(BNB);
        depositParams._portfolioTokenIndex[0] = 0;
        depositParams._isExternalPosition[0] = false;

        // This should revert when trying to set zero approval for BNB
        vm.expectRevert();
        depositBatch.multiTokenSwapAndDeposit(batchData, depositParams, user);
    }
}


contract BNBZeroAFpprovalTest is Test {
    IBNB constant BNB = IBNB(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
    
    function testBNBZeroApRRprovalReverts() public {
        address bnbWhale = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
        // This will revert due to BNB's implementation
        
        vm.prank(bnbWhale);
        vm.expectRevert();
        BNB.approve(address(1), 0); //similar to the 0 value approval in the DepositBatchExternalPositions contract
    }
}