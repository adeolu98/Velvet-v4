# Zero-Value Approval Revert in BNB Token Interactions

## Summary
The `DepositBatchExternalPositions` contract attempts to set zero approvals for tokens before setting new approval values, but this pattern fails with the BNB token on Ethereum mainnet as its implementation explicitly rejects zero-value approvals.

The project application is said to support eth and bsc network. In this case where this contract wont work with BNB token on eth mainnet. We cannot say that the project should ban/blacklist BNB from its application as the BNB token is a very popular token among users. 

## Finding Description
In the `multiTokenSwapAndDeposit` function of `DepositBatchExternalPositions`, the contract follows a common safety pattern of resetting approvals to zero before setting new approval values:

```solidity
for (uint256 i; i < tokenLength; i++) {
    address _token = tokens[i];
    TransferHelper.safeApprove(_token, target, 0); // Will revert for BNB token
    TransferHelper.safeApprove(_token, target, depositAmounts[i]);
}
```

However, the BNB token's contract on Ethereum mainnet (0xB8c77482e45F1F44dE1745F52C74426C631bDD52) has a unique implementation that explicitly rejects zero-value approvals:

```solidity
function approve(address _spender, uint256 _value)
    returns (bool success) {
    if (_value <= 0) throw; // Explicitly rejects zero or negative values
    allowance[msg.sender][_spender] = _value;
    return true;
}
```

This means that any transaction involving BNB token approvals will fail when the contract attempts to reset the approval to zero, making it impossible to deposit or manage BNB tokens through the protocol.

## Impact Explanation
This vulnerability has a HIGH impact because:
1. It completely blocks the use of BNB tokens in the protocol
2. Any multi-token operation that includes BNB will fail
3. Users cannot deposit or manage portfolios containing BNB
4. The issue affects core functionality of the protocol

## Likelihood Explanation
The likelihood is HIGH because:
1. BNB is a major token that users are likely to interact with
2. The issue will occur 100% of the time when interacting with BNB
3. The condition is not dependent on any external factors
4. There is no way to bypass this limitation with the current implementation

## Proof of Concept
Create a test file `test/foundry/BNBZeroApprovalTest.t.sol`:

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/bundle/DepositBatchExternalPositions.sol";

interface IBNB {
    function approve(address spender, uint256 value) external returns (bool);
}

contract BNBZeroApprovalTest is Test {
    IBNB constant BNB = IBNB(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
    
    function testBNBZeroApprovalReverts() public {
        address bnbWhale = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
        // This will revert due to BNB's implementation
        
        vm.prank(bnbWhale);
        vm.expectRevert();
        BNB.approve(address(1), 0); //similar to the 0 value approval in the DepositBatchExternalPositions contract
    }
}
```

## Recommendation
Modify the approval pattern to handle tokens that don't support zero-value approvals. Here are two possible solutions:

1. Skip the zero approval step for known problematic tokens:
```solidity
function _safeApprove(address token, address spender, uint256 amount) internal {
    // List of tokens that don't support zero approvals
    if (token != 0xB8c77482e45F1F44dE1745F52C74426C631bDD52) {
        TransferHelper.safeApprove(token, spender, 0);
    }
    TransferHelper.safeApprove(token, spender, amount);
}
```

2. Use a try-catch pattern to handle failed zero approvals:
```solidity
function _safeApprove(address token, address spender, uint256 amount) internal {
    try IERC20(token).approve(spender, 0) {} catch {}
    TransferHelper.safeApprove(token, spender, amount);
}
```

Replace the current approval pattern in the `multiTokenSwapAndDeposit` function with the new `_safeApprove` function:

```solidity
for (uint256 i; i < tokenLength; i++) {
    address _token = tokens[i];
    _safeApprove(_token, target, depositAmounts[i]);
}
```

This change ensures compatibility with tokens that have non-standard approval behavior while maintaining the security benefits of the approval reset pattern for standard tokens.
