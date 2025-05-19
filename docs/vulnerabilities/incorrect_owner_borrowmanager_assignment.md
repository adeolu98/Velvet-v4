# Vulnerability Report: Incorrect Parameter Assignment in PortfolioFactory.sol

## Summary

A critical vulnerability has been identified in the `PortfolioFactory.sol` contract where the parameters for `owner` and `borrowManager` are incorrectly swapped when creating a new `PortfoliolInfo` struct. This results in the function caller (`msg.sender`) being incorrectly assigned as the `borrowManager` and the actual `borrowManager` address being incorrectly assigned as the `owner`.

## Vulnerability Details

### Location
File: `/contracts/PortfolioFactory.sol`
Lines: 344-345

### Code Snippet
```solidity
PortfolioInfolList.push(
  PortfoliolInfo(
    address(portfolio),
    address(_tokenExclusionManager),
    address(rebalancing),
    address(borrowManager), //@audit wrong value, function caller/owner is set as borrow manager
    msg.sender, //@audit wrong value, msg.sender is set as borrow manager
    address(_assetManagementConfig),
    address(_feeModule),
    address(vaultAddress),
    address(module)
  )
);
```

### PortfoliolInfo Struct Definition
```solidity
struct PortfoliolInfo {
  address portfolio;
  address tokenExclusionManager;
  address rebalancing;
  address owner;
  address borrowManager;
  address assetManagementConfig;
  address feeModule;
  address vaultAddress;
  address gnosisModule;
}
```

## Impact

This vulnerability has several serious implications:

1. **Incorrect Ownership**: The `borrowManager` address is incorrectly set as the `owner` of the portfolio, which means the actual portfolio creator (the function caller) loses ownership rights.

2. **Privilege Escalation**: The function caller (`msg.sender`) is incorrectly assigned as the `borrowManager`, potentially granting them unintended privileges associated with the borrow manager role.

3. **Access Control Issues**: Any functions that rely on the correct `owner` or `borrowManager` addresses will operate with incorrect permissions, potentially allowing unauthorized operations or denying legitimate operations.

4. **System Integrity**: The overall integrity of the portfolio management system is compromised as the fundamental ownership and role structure is incorrectly established.

## Recommendation

The parameters should be swapped to correctly assign the `owner` and `borrowManager` addresses:

```solidity
PortfolioInfolList.push(
  PortfoliolInfo(
    address(portfolio),
    address(_tokenExclusionManager),
    address(rebalancing),
    msg.sender, // Correct: function caller is the owner
    address(borrowManager), // Correct: borrowManager address is assigned to borrowManager field
    address(_assetManagementConfig),
    address(_feeModule),
    address(vaultAddress),
    address(module)
  )
);
```

This correction ensures that:
1. The function caller (`msg.sender`) is properly set as the `owner` of the portfolio
2. The `borrowManager` address is properly assigned to the `borrowManager` field in the struct

## Additional Notes

This vulnerability highlights the importance of careful parameter ordering when constructing structs, especially those that define critical system roles and access controls. Consider implementing named parameters or builder patterns for complex structs to make the code more explicit and reduce the risk of parameter ordering errors.
