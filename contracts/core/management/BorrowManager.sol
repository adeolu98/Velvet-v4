// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable-4.9.6/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/UUPSUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable-4.9.6/interfaces/IERC20Upgradeable.sol";
import { TransferHelper } from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import { IBorrowManager } from "../interfaces/IBorrowManager.sol";
import { FunctionParameters } from "../../FunctionParameters.sol";
import { IProtocolConfig } from "../../config/protocol/IProtocolConfig.sol";
import { IVenusPool } from "../interfaces/IVenusPool.sol";
import { IThena } from "../interfaces/IThena.sol";
import { IAssetHandler } from "../interfaces/IAssetHandler.sol";
import { ErrorLibrary } from "../../library/ErrorLibrary.sol";
import { IAlgebraPool } from "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPool.sol";
import { AccessModifiers } from "../access/AccessModifiers.sol";
import { IAlgebraFlashCallback } from "@cryptoalgebra/integral-core/contracts/interfaces/callback/IAlgebraFlashCallback.sol";
import { IPortfolio } from "../../core/interfaces/IPortfolio.sol";

/**
 * @title BorrowManager
 * @notice This contract manages the borrowing and repayment of assets using flash loans and handles portfolio withdrawals.
 * @dev Inherits from OwnableUpgradeable, UUPSUpgradeable, AccessModifiers, and IAlgebraFlashCallback.
 */
contract BorrowManager is
  OwnableUpgradeable,
  UUPSUpgradeable,
  AccessModifiers,
  IAlgebraFlashCallback,
  IBorrowManager
{
  // Internal variables to store the vault, protocol configuration, and portfolio addresses
  address internal _vault;
  IProtocolConfig internal _protocolConfig;
  IPortfolio internal _portfolio;

  //Flag to track if a flash loan is currently in progress
  bool _isFlashLoanActive;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers(); // Disables initializers to prevent misuse in the constructor
  }

  /**
   * @notice Initializes the BorrowManager contract with necessary addresses.
   * @param vault The address of the vault to manage.
   * @param protocolConfig The address of the protocol configuration contract.
   * @param portfolio The address of the portfolio contract.
   * @param accessController The address of the access control contract.
   */
  function init(
    address vault,
    address protocolConfig,
    address portfolio,
    address accessController
  ) external override initializer {
    _vault = vault; // Set the vault address
    _protocolConfig = IProtocolConfig(protocolConfig); // Set the protocol configuration
    _portfolio = IPortfolio(portfolio); // Set the portfolio address
    __Ownable_init(); // Initialize Ownable
    __UUPSUpgradeable_init(); // Initialize UUPS upgradeable pattern
    __AccessModifiers_init(accessController); // Initialize access control
  }

  /**
   * @notice Internal function to handle the repayment of borrowed tokens during withdrawal.
   * @param _portfolioTokenAmount The amount of portfolio tokens being withdrawn.
   * @param _totalSupply The total supply of portfolio tokens.
   * @param repayData Data required for repaying the borrow.
   */
  function repayBorrow(
    uint256 _portfolioTokenAmount,
    uint256 _totalSupply,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external onlyPortfolioManager {
    // Get all supported controllers from the protocol configuration
    // There can be multiple controllers from Venus side, hence the loop
    address[] memory controllers = _protocolConfig.getSupportedControllers();

    beforeRepayVerification(
      repayData._factory,
      repayData._solverHandler,
      repayData._bufferUnit
    );

    // Set flash loan flag to true to allow callback execution and prevent unauthorized callbacks
    _isFlashLoanActive = true;

    // Iterate through all controllers to repay borrows for each
    for (uint j; j < controllers.length; j++) {
      address _controller = controllers[j];

      // Get the asset handler for the current controller
      IAssetHandler assetHandler = IAssetHandler(
        _protocolConfig.assetHandlers(_controller)
      );

      (, address[] memory borrowedTokens) = assetHandler.getAllProtocolAssets(
        _vault, //@audit if youre able to add many tokens, of little amounts to the vault, this will cause the loop in this getAllProtocolAssets to fail with OOG. 
        _controller
      ); // Get all borrowed tokens for the vault under the controller

      // Check if there are any borrowed tokens
      if (borrowedTokens.length == 0) continue; // If no borrowed tokens, skip to the next controller

      // Prepare the data for the flash loan execution
      bytes memory data = abi.encodeWithSelector(
        IAssetHandler.executeUserFlashLoan.selector,
        _vault,
        address(this),
        _portfolioTokenAmount,
        _totalSupply,
        borrowedTokens,
        repayData
      );

      // Perform the delegatecall to the asset handler
      // This allows the asset handler to execute the flash loan in the context of this contract
      (bool success, ) = address(assetHandler).delegatecall(data);

      // Check if the delegatecall was successful
      // If not, revert the transaction with a custom error
      if (!success) revert ErrorLibrary.CallFailed();
    }
  }

  /**
   * @notice Handles the repayment of the vault's debt using a flash loan.
   * @param repayData Data required for the repayment process.
   */
  function repayVault(
    address _controller,
    FunctionParameters.RepayParams calldata repayData
  ) external onlyRebalancerContract returns (bool) {
    IAssetHandler assetHandler = IAssetHandler(
      _protocolConfig.assetHandlers(_controller)
    );

    beforeRepayVerification(
      repayData._factory,
      repayData._solverHandler,
      repayData._bufferUnit
    );

    // Get the number of borrowed tokens before the flash loan repayment
    uint256 borrowedLengthBefore = (
      assetHandler.getBorrowedTokens(_vault, _controller)
    ).length;

    // Prepare the data for the flash loan execution
    // This includes the function selector and parameters needed for the vault flash loan
    bytes memory data = abi.encodeWithSelector(
      IAssetHandler.executeVaultFlashLoan.selector,
      address(this),
      repayData
    );

    // Set flash loan flag to true to allow callback execution and prevent unauthorized callbacks
    _isFlashLoanActive = true;

    // Perform a delegatecall to the asset handler
    // delegatecall allows the asset handler's code to be executed in the context of this contract
    // maintaining this contract's storage while using the asset handler's logic
    (bool success, ) = address(assetHandler).delegatecall(data);

    // Check if the delegatecall was successful
    if (!success) revert ErrorLibrary.CallFailed();

    // Get the number of borrowed tokens after the flash loan repayment
    uint256 borrowedLengthAfter = (
      assetHandler.getBorrowedTokens(_vault, _controller)
    ).length;

    // Return true if we successfully reduced the number of borrowed tokens
    // This indicates that at least one borrow position was fully repaid
    return borrowedLengthAfter < borrowedLengthBefore;
  }

  /**
   * @notice Callback function for Algebra flash loans.
   * @dev This function handles the logic after receiving the flash loan, such as repaying debt and performing swaps.
   * @param fee0 The fee for the borrowed token.
   * @param fee1 The fee for the paired token (if borrowed).
   * @param data Encoded data passed from the flash loan.
   */
  function algebraFlashCallback(
    uint256 fee0,
    uint256 fee1,
    bytes calldata data
  ) external override {
    //Ensure flash loan is active to prevent unauthorized callbacks
    if (!_isFlashLoanActive) revert ErrorLibrary.FlashLoanIsInactive();

    FunctionParameters.FlashLoanData memory flashData = abi.decode(
      data,
      (FunctionParameters.FlashLoanData)
    ); // Decode the flash loan data

    IAssetHandler assetHandler = IAssetHandler(
      _protocolConfig.assetHandlers(flashData.protocolTokens[0])
    ); // Get the asset handler for the protocol tokens
    address controller = _protocolConfig.marketControllers(
      flashData.protocolTokens[0]
    ); // Get the market controller for the protocol token

    // Get user account data, including total collateral and debt
    (
      FunctionParameters.AccountData memory accountData,
      FunctionParameters.TokenAddresses memory tokenBalances
    ) = assetHandler.getUserAccountData(_vault, controller);

    // Process the loan to generate the transactions needed for repayment and swaps
    (
      IAssetHandler.MultiTransaction[] memory transactions,
      uint256 totalFlashAmount
    ) = assetHandler.loanProcessing(
        _vault,
        address(_portfolio),
        controller,
        address(this),
        tokenBalances.lendTokens,
        accountData.totalCollateral,
        IThena(msg.sender).globalState().fee,
        flashData
      );

    // Execute each transaction in the sequence
    for (uint i; i < transactions.length; i++) {
      (bool success, ) = transactions[i].to.call(transactions[i].txData); // Execute the transaction
      if (!success) revert ErrorLibrary.CallFailed(); // Revert if the call fails
    }

    // Calculate the fee based on the token0 and fee0/fee1,using the Algebra Pool
    uint256 fee = IAlgebraPool(msg.sender).token0() == flashData.flashLoanToken
      ? fee0
      : fee1;

    // Calculate the amount owed including the fee
    uint256 amountOwed = totalFlashAmount + fee;

    // Transfer the amount owed back to the flashLoan provider
    TransferHelper.safeTransfer(
      flashData.flashLoanToken,
      msg.sender,
      amountOwed
    );

    // Transfer any remaining dust balance back to the vault
    TransferHelper.safeTransfer(
      flashData.flashLoanToken,
      _vault,
      IERC20Upgradeable(flashData.flashLoanToken).balanceOf(address(this))
    );

    //Reset the flash loan state to prevent subsequent unauthorized callbacks
    _isFlashLoanActive = false;
  }

  function beforeRepayVerification(
    address _factory,
    address _solverHandler,
    uint256 _bufferUnit
  ) internal view {
    if (!_protocolConfig.isSupportedFactory(_factory))
      revert ErrorLibrary.InvalidFactoryAddress();

    if (!_protocolConfig.isSolver(_solverHandler))
      revert ErrorLibrary.InvalidSolver();

    if (_protocolConfig.MAX_COLLATERAL_BUFFER_UNIT() < _bufferUnit)
      revert ErrorLibrary.InvalidBufferUnit();
  }

  /**
   * @notice Authorizes the upgrade of the contract.
   * @param newImplementation Address of the new implementation.
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {
    // Intentionally left empty as required by an abstract contract
  }
}
