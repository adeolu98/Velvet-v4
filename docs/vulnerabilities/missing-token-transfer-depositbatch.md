# Vulnerability Report: Missing Token Transfer in DepositBatch Contract

## Description
The `DepositBatch` contract's `multiTokenSwapAndDeposit` function fails to transfer tokens from the user to the contract before attempting to perform swaps. This critical vulnerability allows attackers to front-run legitimate user transactions and steal tokens that users have manually transferred to the contract.

## Vulnerability Details
```solidity
function multiTokenSwapAndDeposit(
  FunctionParameters.BatchHandler memory data,
  address user
) external payable nonReentrant {
  address _depositToken = data._depositToken;

  _multiTokenSwapAndDeposit(data, user);  //this function does not transfer tokens from user to the contract before proceeding to swap it. also if it is claimed that user will manually transfer to contract before that is suceptible to frontrunning/stealing by an attacker

  // Return any leftover invested token dust to the user
  uint256 depositTokenBalance = _getTokenBalance(
    _depositToken,
    address(this)
  );
  if (depositTokenBalance > 0) {
    TransferHelper.safeTransfer(_depositToken, user, depositTokenBalance);
  }
}
```

The issue arises because:
1. The `_multiTokenSwapAndDeposit` function assumes that tokens are already in the contract's balance when it attempts to perform swaps and deposits
2. There is no call to `transferFrom` to move tokens from the user to the contract before proceeding
3. If users manually transfer tokens to the contract before calling `multiTokenSwapAndDeposit`, an attacker can monitor the blockchain for such transfers
4. The attacker can front-run the user's transaction by calling `multiTokenSwapAndDeposit` with their own parameters, effectively stealing the user's tokens

## Impact
- **Direct Theft of User Funds**: Attackers can steal tokens that users have transferred to the contract.
- **Loss of Trust**: Users may lose confidence in the protocol after experiencing or hearing about such thefts.
- **Financial Losses**: The protocol and its users could suffer significant financial losses.
- **Broken Protocol Flow**: The intended flow of the protocol is broken, as users cannot successfully use the `multiTokenSwapAndDeposit` function without manually transferring tokens first, which exposes them to front-running attacks.

## Recommendation
Modify the `multiTokenSwapAndDeposit` function to properly transfer tokens from the user to the contract before proceeding with swaps:

```solidity
function multiTokenSwapAndDeposit(
  FunctionParameters.BatchHandler memory data,
  address user
) external payable nonReentrant {
  address _depositToken = data._depositToken;
  
  // Transfer tokens from user to this contract first
  TransferHelper.safeTransferFrom(
    _depositToken, 
    msg.sender, 
    address(this), 
    data._depositAmount
  );
  
  _multiTokenSwapAndDeposit(data, user);
  
  // Return any leftover invested token dust to the user
  uint256 depositTokenBalance = _getTokenBalance(
    _depositToken,
    address(this)
  );
  if (depositTokenBalance > 0) {
    TransferHelper.safeTransfer(_depositToken, user, depositTokenBalance);
  }
}
```

Additionally:
1. Implement proper approval checks to ensure that the contract has sufficient allowances before attempting to transfer tokens.
2. Consider using a permit-style approach (EIP-2612) to allow users to sign messages off-chain to approve token transfers, reducing the number of transactions needed and mitigating front-running risks.

## Proof of Concept
A test demonstrating this issue can be found in `test/foundry/DepositBatchBugPOC.t.sol`. The test shows that:
1. A user transfers tokens to the `DepositBatch` contract manually
2. Before the user can call `multiTokenSwapAndDeposit`, an attacker front-runs them
3. The attacker calls `multiTokenSwapAndDeposit` with their own parameters, using the tokens that the user has already transferred
4. The contract processes the attacker's request using the user's tokens
5. The tokens are deposited to the attacker's portfolio or returned to the attacker

The function `testShowWhatHappensIfManualDepositIsAllowed()` specifically demonstrates how an attacker can steal tokens that a user has manually transferred to the contract.
