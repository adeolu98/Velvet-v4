// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/token/ERC20/IERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/security/ReentrancyGuardUpgradeable.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IVelvetSafeModule} from "../../vault/IVelvetSafeModule.sol";
import {IPortfolio} from "../interfaces/IPortfolio.sol";
import {FeeManager} from "./FeeManager.sol";
import {VaultConfig, ErrorLibrary} from "../config/VaultConfig.sol";
import {VaultCalculations, Dependencies} from "../calculations/VaultCalculations.sol";
import {MathUtils} from "../calculations/MathUtils.sol";
import {PortfolioToken} from "../token/PortfolioToken.sol";
import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";
import {IProtocolConfig} from "../../config/protocol/IProtocolConfig.sol";
import {IThena} from "../interfaces/IThena.sol";
import {IVenusPool} from "../interfaces/IVenusPool.sol";
import {FunctionParameters} from "../../FunctionParameters.sol";
import "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPool.sol";
import "@cryptoalgebra/integral-core/contracts/interfaces/callback/IAlgebraFlashCallback.sol";
import {IAssetHandler} from "../interfaces/IAssetHandler.sol";
import {TokenBalanceLibrary} from "../calculations/TokenBalanceLibrary.sol";
import {IBorrowManager} from "../interfaces/IBorrowManager.sol";

/**
 * @title VaultManager
 * @dev Extends functionality for managing deposits and withdrawals in the vault.
 * Combines configurations, calculations, fee handling, and token operations.
 */
abstract contract VaultManager is
  VaultConfig,
  VaultCalculations,
  FeeManager,
  ReentrancyGuardUpgradeable,
  PortfolioToken
{
  IAllowanceTransfer public immutable permit2 =
    IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

  IProtocolConfig internal _protocolConfig;
  IBorrowManager internal _borrowManager;

  /**
   * @notice Initializes the VaultManager contract.
   * @dev This function sets up the ReentrancyGuard by calling its initializer. It's designed to be called
   *      during the contract initialization process to ensure that the non-reentrant modifier can be used
   *      safely in functions to prevent reentrancy attacks. This is a standard part of setting up contracts
   *      that handle external calls or token transfers, providing an additional layer of security.
   * @param protocolConfig The address of the protocol configuration contract.
   */
  function __VaultManager_init(
    address protocolConfig,
    address borrowManager
  ) internal onlyInitializing {
    _protocolConfig = IProtocolConfig(protocolConfig);
    _borrowManager = IBorrowManager(borrowManager);
    __ReentrancyGuard_init();
  }

  /**
   * @notice Allows the sender to deposit tokens into the fund through a multi-token deposit.
   *         The deposited tokens are added to the vault, and the user is minted portfolio tokens representing their share.
   * @param depositAmounts An array of amounts corresponding to each token the user wishes to deposit.
   * @param _minMintAmount The minimum amount of portfolio tokens the user expects to receive for their deposit, protecting against slippage.
   * @param _permit Batch permit data for token allowance.
   * @param _signature Signature corresponding to the permit batch.
   * @dev This function facilitates the process for the sender to deposit multiple tokens into the vault.
   *      It updates the vault and mints new portfolio tokens for the user.
   *      The nonReentrant modifier is used to prevent reentrancy attacks.
   */
  function multiTokenDeposit(
    uint256[] calldata depositAmounts,
    uint256 _minMintAmount,
    IAllowanceTransfer.PermitBatch calldata _permit,
    bytes calldata _signature
  ) external virtual nonReentrant {
    _multiTokenDepositWithPermit(
      msg.sender,
      depositAmounts,
      _minMintAmount,
      _permit,
      _signature
    );
  }

  /**
   * @notice Allows a specified depositor to deposit tokens into the fund through a multi-token deposit.
   *         The deposited tokens are added to the vault, and the user is minted portfolio tokens representing their share.
   * @param _depositFor The address of the user the deposit is being made for.
   * @param depositAmounts An array of amounts corresponding to each token the user wishes to deposit.
   * @param _minMintAmount The minimum amount of portfolio tokens the user expects to receive for their deposit, protecting against slippage.
   * @dev This function ensures that the depositor is making a multi-token deposit on behalf of another user.
   *      It handles the deposit process, updates the vault, and mints new portfolio tokens for the user.
   *      The nonReentrant modifier is used to prevent reentrancy attacks.
   */
  function multiTokenDepositFor(
    address _depositFor,
    uint256[] calldata depositAmounts,
    uint256 _minMintAmount
  ) external virtual nonReentrant {
    _multiTokenDeposit(_depositFor, depositAmounts, _minMintAmount);
  }

  /**
   * @notice Allows an approved user to withdraw portfolio tokens on behalf of another user.
   * @param _withdrawFor The address of the user for whom the withdrawal is being made.
   * @param _tokenReceiver The address of the user who receives the withdrawn tokens.
   * @param _portfolioTokenAmount The amount of portfolio tokens to withdraw.
   */
  function multiTokenWithdrawalFor(
    address _withdrawFor,
    address _tokenReceiver,
    uint256 _portfolioTokenAmount,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external virtual nonReentrant {
    _spendAllowance(_withdrawFor, msg.sender, _portfolioTokenAmount);
    address[] memory _emptyArray;
    _multiTokenWithdrawal(
      _withdrawFor,
      _tokenReceiver,
      _portfolioTokenAmount,
      _emptyArray,
      repayData
    );
  }

  /**
   * @notice Allows users to withdraw their deposit from the fund, receiving the underlying tokens.
   * @param _portfolioTokenAmount The amount of portfolio tokens to withdraw.
   */
  function multiTokenWithdrawal(
    uint256 _portfolioTokenAmount,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external virtual nonReentrant {
    address[] memory _emptyArray;
    _multiTokenWithdrawal(
      msg.sender,
      msg.sender,
      _portfolioTokenAmount,
      _emptyArray,
      repayData
    );
  }

  /**
   * @notice Allows users to perform an emergency withdrawal from the fund, receiving the underlying tokens.
   * @dev This function enables users to withdraw their portfolio tokens and receive the corresponding underlying tokens.
   * In the event of a transfer failure for any of the specified exemption tokens, the function will catch the error
   * and continue processing the remaining tokens, ensuring that the user can retrieve their assets even if some tokens
   * are non-transferable.
   * @param _portfolioTokenAmount The amount of portfolio tokens to withdraw.
   * @param _exemptionTokens An array of token addresses that are exempt from withdrawal if their transfer fails.
   */
  function emergencyWithdrawal(
    uint256 _portfolioTokenAmount,
    address[] memory _exemptionTokens,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external virtual nonReentrant {
    _multiTokenWithdrawal(
      msg.sender,
      msg.sender,
      _portfolioTokenAmount,
      _exemptionTokens,
      repayData
    );
  }

  /**
   * @notice Allows an authorized user to perform an emergency withdrawal on behalf of another user.
   * @dev This function enables an authorized user to withdraw portfolio tokens on behalf of another user and
   * send the corresponding underlying tokens to a specified receiver address. If the transfer of any of the
   * specified exemption tokens fails, the function will catch the error and continue processing the remaining
   * tokens, ensuring that the assets can be retrieved even if some tokens are non-transferable.
   * @param _withdrawFor The address of the user on whose behalf the withdrawal is being performed.
   * @param _tokenReceiver The address that will receive the underlying tokens.
   * @param _portfolioTokenAmount The amount of portfolio tokens to withdraw.
   * @param _exemptionTokens An array of token addresses that are exempt from withdrawal if their transfer fails.
   */
  function emergencyWithdrawalFor(
    address _withdrawFor,
    address _tokenReceiver,
    uint256 _portfolioTokenAmount,
    address[] memory _exemptionTokens,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external virtual nonReentrant {
    _spendAllowance(_withdrawFor, msg.sender, _portfolioTokenAmount);
    _multiTokenWithdrawal(
      _withdrawFor,
      _tokenReceiver,
      _portfolioTokenAmount,
      _exemptionTokens,
      repayData
    );
  }

  /**
   * @notice Allows the rebalancer contract to pull tokens from the vault.
   * @dev Executes a token transfer via the VelvetSafeModule, ensuring secure transaction execution.
   * @param _token The token to be pulled from the vault.
   * @param _amount The amount of the token to pull.
   * @param _to The destination address for the tokens.
   */
  function pullFromVault(
    address _token,
    uint256 _amount,
    address _to
  ) external onlyRebalancerContract {
    _pullFromVault(_token, _amount, _to);
  }

  /**
   * @notice Internal function to handle the withdrawal of tokens from the vault.
   * @param _token The token to be pulled from the vault.
   * @param _amount The amount of the token to pull.
   * @param _to The destination address for the tokens.
   */
  function _pullFromVault(
    address _token,
    uint256 _amount,
    address _to
  ) internal {
    bytes memory inputData = abi.encodeWithSelector(
      IERC20Upgradeable.transfer.selector,
      _to,
      _amount
    );
    (, bytes memory data) = IVelvetSafeModule(safeModule).executeWallet(
      _token,
      inputData
    );
    if (!(data.length == 0 || abi.decode(data, (bool)))) {
      revert ErrorLibrary.TransferFailed();
    }
  }

  /**
   * @dev Claims rewards for a target address by executing a transfer through the safe module.
   * Only the rebalancer contract is allowed to call this function.
   * @param _target The address where the rewards are claimed from.
   * @param _claimCalldata The calldata to be used for the claim.
   */
  function vaultInteraction(
    address _target,
    bytes memory _claimCalldata
  ) external onlyRebalancerContract {
    _vaultInteraction(_target, _claimCalldata);
  }

  /**
   * @notice Internal function to interact with the vault.
   * @dev Executes the interaction through the safe module and checks for success.
   * @param _target The address where the interaction is targeted.
   * @param _claimCalldata The calldata to be used for the interaction.
   */
  function _vaultInteraction(
    address _target,
    bytes memory _claimCalldata
  ) internal {
    (, bytes memory data) = IVelvetSafeModule(safeModule).executeWallet(
      _target,
      _claimCalldata
    );
  }

  /**
   * @notice Internal function to handle the multi-token deposit logic with permit.
   * @param _depositFor The address of the user the deposit is being made for.
   * @param depositAmounts An array of amounts corresponding to each token the user wishes to deposit.
   * @param _minMintAmount The minimum amount of portfolio tokens the user expects to receive for their deposit, protecting against slippage.
   * @param _permit Batch permit data for token allowance.
   * @param _signature Signature corresponding to the permit batch.
   */
  function _multiTokenDepositWithPermit(
    address _depositFor,
    uint256[] calldata depositAmounts,
    uint256 _minMintAmount,
    IAllowanceTransfer.PermitBatch calldata _permit,
    bytes calldata _signature
  ) internal virtual {
    if (_permit.spender != address(this)) revert ErrorLibrary.InvalidSpender();
    _beforeDepositCheck(_depositFor, tokens.length);
    _chargeFees(_depositFor);
    uint256 _depositRatio = _multiTokenTransferWithPermit(
      depositAmounts,
      _permit,
      _signature,
      msg.sender
    );
    _depositAndMint(_depositFor, _minMintAmount, _depositRatio);
  }

  /**
   * @notice Internal function to handle the multi-token deposit logic.
   * @param _depositFor The address of the user the deposit is being made for.
   * @param depositAmounts An array of amounts corresponding to each token the user wishes to deposit.
   * @param _minMintAmount The minimum amount of portfolio tokens the user expects to receive for their deposit, protecting against slippage.
   */
  function _multiTokenDeposit(
    address _depositFor,
    uint256[] calldata depositAmounts,
    uint256 _minMintAmount
  ) internal virtual {
    _beforeDepositCheck(_depositFor, tokens.length);
    _chargeFees(_depositFor);
    uint256 _depositRatio = _multiTokenTransfer(msg.sender, depositAmounts);
    _depositAndMint(_depositFor, _minMintAmount, _depositRatio);
  }

  /**
   * @notice Handles the deposit and minting process for a given user.
   * @param _depositFor The address for which the deposit is made.
   * @param _minMintAmount The minimum amount of portfolio tokens to mint for the user.
   * @param _depositRatio The ratio used to calculate the amount of tokens to mint based on the deposit.
   */
  function _depositAndMint(
    address _depositFor,
    uint256 _minMintAmount,
    uint256 _depositRatio
  ) internal {
    uint256 _totalSupply = totalSupply();
    uint256 tokenAmount;

    if (_totalSupply == 0) {
      tokenAmount = assetManagementConfig().initialPortfolioAmount();
      feeModule().resetHighWaterMark();
    } else {
      tokenAmount = _getTokenAmountToMint(_depositRatio, _totalSupply);
    }

    tokenAmount = _mintTokenAndSetCooldown(_depositFor, tokenAmount);
    _verifyUserMintedAmount(tokenAmount, _minMintAmount);

    emit Deposited(
      address(this),
      _depositFor,
      tokenAmount,
      balanceOf(_depositFor)
    );
  }

  /**
   * @notice Internal function to handle the multi-token withdrawal logic.
   * @param _withdrawFor The address of the user making the withdrawal.
   * @param _portfolioTokenAmount The amount of portfolio tokens to burn for withdrawal.
   * @param _tokenReceiver The address to receive the withdrawn tokens.
   * @param _exemptionTokens The array of tokens that are exempt from withdrawal if transfer fails.
   */
  function _multiTokenWithdrawal(
    address _withdrawFor,
    address _tokenReceiver,
    uint256 _portfolioTokenAmount,
    address[] memory _exemptionTokens,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) internal virtual {
    address[] memory portfolioTokens = tokens;
    uint256 portfolioTokenLength = portfolioTokens.length;

    _beforeWithdrawCheck(
      _withdrawFor,
      IPortfolio(address(this)),
      _portfolioTokenAmount,
      portfolioTokenLength,
      _exemptionTokens
    );

    _checkCoolDownPeriod(_withdrawFor);
    _chargeFees(_withdrawFor);

    uint256 totalSupplyPortfolio = totalSupply();
    _portfolioTokenAmount = _burnWithdraw(_withdrawFor, _portfolioTokenAmount);

    uint256[] memory userWithdrawalAmounts = new uint256[](
      portfolioTokenLength
    );

    uint256 exemptionIndex = 0;
    _borrowManager.repayBorrow(
      _portfolioTokenAmount,
      totalSupplyPortfolio,
      repayData
    );

    for (uint256 i; i < portfolioTokenLength; i++) {
      address _token = portfolioTokens[i];
      uint256 tokenBalance = TokenBalanceLibrary._getTokenBalanceOf(
        _token,
        vault,
        _protocolConfig
      );
      tokenBalance =
        (tokenBalance * _portfolioTokenAmount) /
        totalSupplyPortfolio;

      bytes memory inputData = abi.encodeWithSelector(
        IERC20Upgradeable.transfer.selector,
        _tokenReceiver,
        tokenBalance
      );

      try IVelvetSafeModule(safeModule).executeWallet(_token, inputData) {
        if (tokenBalance == 0 && _exemptionTokens[exemptionIndex] != _token)
          revert ErrorLibrary.WithdrawalAmountIsSmall();
        userWithdrawalAmounts[i] = tokenBalance;
      } catch {
        if (_exemptionTokens[exemptionIndex] != _token) {
          revert ErrorLibrary.InvalidExemptionTokens();
        }
        userWithdrawalAmounts[i] = 0;
        exemptionIndex++;
      }
    }

    emit Withdrawn(
      _withdrawFor,
      _portfolioTokenAmount,
      address(this),
      portfolioTokens,
      balanceOf(_withdrawFor),
      userWithdrawalAmounts
    );
  }

  /**
   * @notice Transfers tokens from the user to the vault using permit2 transferfrom.
   * @dev Utilizes `TransferHelper` for secure token transfer from user to vault.
   * @param _token Address of the token to be transferred.
   * @param _depositAmount Amount of the token to be transferred.
   */
  function _transferToVaultWithPermit(
    address _from,
    address _token,
    uint256 _depositAmount
  ) internal {
    permit2.transferFrom(
      _from,
      vault,
      MathUtils.safe160(_depositAmount),
      _token
    );
  }

  /**
   * @notice Transfers tokens from the user to the vault.
   * @dev Utilizes `TransferHelper` for secure token transfer from user to vault.
   * @param _token Address of the token to be transferred.
   * @param _depositAmount Amount of the token to be transferred.
   * @param _from The address from which the tokens are transferred.
   */
  function _transferToVault(
    address _from,
    address _token,
    uint256 _depositAmount
  ) internal {
    TransferHelper.safeTransferFrom(_token, _from, vault, _depositAmount);
  }

  /**
   * @notice Processes multi-token deposits by calculating the minimum deposit ratio.
   * @dev Ensures that the deposited token amounts align with the current vault token ratios.
   * @param depositAmounts Array of amounts for each token the user wants to deposit.
   * @param _permit Batch permit data for token allowance.
   * @param _signature Signature corresponding to the permit batch.
   * @param _from The address from which the tokens are transferred.
   * @return The minimum deposit ratio after deposits.
   */
  function _multiTokenTransferWithPermit(
    uint256[] calldata depositAmounts,
    IAllowanceTransfer.PermitBatch calldata _permit,
    bytes calldata _signature,
    address _from
  ) internal returns (uint256) {
    (
      uint256 amountLength,
      address[] memory portfolioTokens,
      uint256[] memory tokenBalancesBefore
    ) = _validateAndGetBalances(depositAmounts);

    try permit2.permit(msg.sender, _permit, _signature) {
      // No further implementation needed if permit succeeds
    } catch {
      for (uint256 i; i < depositAmounts.length; i++) {
        if (
          IERC20Upgradeable(portfolioTokens[i]).allowance(
            msg.sender,
            address(this)
          ) < depositAmounts[i]
        ) revert ErrorLibrary.InsufficientAllowance();
      }
    }

    return
      _handleTokenTransfer(
        _from,
        amountLength,
        depositAmounts,
        portfolioTokens,
        tokenBalancesBefore,
        true
      );
  }

  /**
   * @notice Processes multi-token deposits by calculating the minimum deposit ratio.
   * @dev Ensures that the deposited token amounts align with the current vault token ratios.
   * @param depositAmounts Array of amounts for each token the user wants to deposit.
   * @param _from The address from which the tokens are transferred.
   * @return The minimum deposit ratio after deposits.
   */
  function _multiTokenTransfer(
    address _from,
    uint256[] calldata depositAmounts
  ) internal returns (uint256) {
    (
      uint256 amountLength,
      address[] memory portfolioTokens,
      uint256[] memory tokenBalancesBefore
    ) = _validateAndGetBalances(depositAmounts);

    return
      _handleTokenTransfer(
        _from,
        amountLength,
        depositAmounts,
        portfolioTokens,
        tokenBalancesBefore,
        false
      );
  }

  /**
   * @notice Validates deposit amounts and retrieves initial token balances.
   * @param depositAmounts Array of deposit amounts for each token.
   * @return amountLength The length of the deposit amounts array.
   * @return portfolioTokens Array of portfolio tokens.
   * @return tokenBalancesBefore Array of token balances before transfer.
   */
  function _validateAndGetBalances(
    uint256[] calldata depositAmounts
  ) internal view returns (uint256, address[] memory, uint256[] memory) {
    uint256 amountLength = depositAmounts.length;
    address[] memory portfolioTokens = tokens;

    if (amountLength != portfolioTokens.length) {
      revert ErrorLibrary.InvalidDepositInputLength();
    }

    uint256[] memory tokenBalancesBefore = TokenBalanceLibrary
      .getTokenBalancesOf(portfolioTokens, vault, _protocolConfig);

    return (amountLength, portfolioTokens, tokenBalancesBefore);
  }

  /**
   * @notice Handles the token transfer and minRatio calculations.
   * @param _from Address from which tokens are transferred.
   * @param amountLength The length of the deposit amounts array.
   * @param depositAmounts Array of deposit amounts for each token.
   * @param portfolioTokens Array of portfolio tokens.
   * @param tokenBalancesBefore Array of token balances before transfer.
   * @param usePermit Boolean flag to use permit for transfer.
   * @return The minimum ratio after transfer.
   */
  function _handleTokenTransfer(
    address _from,
    uint256 amountLength,
    uint256[] calldata depositAmounts,
    address[] memory portfolioTokens,
    uint256[] memory tokenBalancesBefore,
    bool usePermit
  ) internal returns (uint256) {
    //Array to store deposited amouts of user
    uint256[] memory depositedAmounts = new uint256[](amountLength);

    // If the vault is empty, accept the deposits and return zero as the initial ratio
    if (totalSupply() == 0) {
      for (uint256 i; i < amountLength; i++) {
        uint256 depositAmount = depositAmounts[i];
        if (depositAmount == 0) revert ErrorLibrary.AmountCannotBeZero();
        address portfolioToken = portfolioTokens[i];
        if (usePermit) {
          _transferToVaultWithPermit(_from, portfolioToken, depositAmount);
        } else {
          // TransferHelper.safeTransferFrom(portfolioToken, _from, vault, depositAmount);
          _transferToVault(_from, portfolioToken, depositAmount);
        }

        if (
          TokenBalanceLibrary._getTokenBalanceOf(
            portfolioToken,
            vault,
            _protocolConfig
          ) <= tokenBalancesBefore[i]
        ) revert ErrorLibrary.TransferFailed();
        depositedAmounts[i] = depositAmount;
      }
      emit UserDepositedAmounts(depositedAmounts, portfolioTokens);
      return 0;
    }

    uint256 _minRatio = type(uint).max;
    for (uint256 i = 0; i < amountLength; i++) {
      uint256 _currentRatio = _getDepositToVaultBalanceRatio(
        depositAmounts[i],
        tokenBalancesBefore[i]
      );
      _minRatio = MathUtils._min(_currentRatio, _minRatio);
    }

    uint256 transferAmount;
    uint256 _minRatioAfterTransfer = type(uint256).max;
    for (uint256 i; i < amountLength; i++) {
      address token = portfolioTokens[i];
      uint256 tokenBalanceBefore = tokenBalancesBefore[i];
      transferAmount = (_minRatio * tokenBalanceBefore) / ONE_ETH_IN_WEI;
      depositedAmounts[i] = transferAmount;
      if (usePermit) {
        _transferToVaultWithPermit(_from, token, transferAmount);
      } else {
        _transferToVault(_from, token, transferAmount);
      }

      uint256 tokenBalanceAfter = TokenBalanceLibrary._getTokenBalanceOf(
        token,
        vault,
        _protocolConfig
      );
      uint256 currentRatio = _getDepositToVaultBalanceRatio(
        tokenBalanceAfter - tokenBalanceBefore,
        tokenBalanceAfter
      );
      _minRatioAfterTransfer = MathUtils._min(
        currentRatio,
        _minRatioAfterTransfer
      );
    }
    emit UserDepositedAmounts(depositedAmounts, portfolioTokens);
    return _minRatioAfterTransfer;
  }
}
