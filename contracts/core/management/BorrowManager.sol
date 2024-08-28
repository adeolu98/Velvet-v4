// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/interfaces/IERC20Upgradeable.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IBorrowManager} from "../interfaces/IBorrowManager.sol";
import {FunctionParameters} from "../../FunctionParameters.sol";
import {IProtocolConfig} from "../../config/protocol/IProtocolConfig.sol";
import {IVenusPool} from "../interfaces/IVenusPool.sol";
import {IThena} from "../interfaces/IThena.sol";
import {IAssetHandler} from "../interfaces/IAssetHandler.sol";
import {ErrorLibrary} from "../../library/ErrorLibrary.sol";
import {IAlgebraPool} from "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPool.sol";
import {AccessModifiers} from "../access/AccessModifiers.sol";
import {IAlgebraFlashCallback} from "@cryptoalgebra/integral-core/contracts/interfaces/callback/IAlgebraFlashCallback.sol";
import {IPortfolio} from "../../core/interfaces/IPortfolio.sol";

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
    function repayDeposit(
        uint256 _portfolioTokenAmount,
        uint256 _totalSupply,
        FunctionParameters.withdrawRepayParams calldata repayData
    ) external onlyPortfolioManager {
        address[] memory controllers = _protocolConfig
            .getSupportedControllers(); // Get all supported controllers
        for (uint j; j < controllers.length; j++) {
            IAssetHandler assetHandler = IAssetHandler(
                _protocolConfig.assetHandlers(controllers[j])
            );

            (, address[] memory borrowedTokens) = assetHandler
                .getAllProtocolAssets(_vault, controllers[j]); // Get all borrowed tokens for the vault under the controller
            uint borrowedLength = borrowedTokens.length;
            if (borrowedLength != 0) {
                address[] memory underlying = new address[](borrowedLength); // Array to store underlying tokens of borrowed assets
                uint256[] memory tokenBalance = new uint256[](borrowedLength); // Array to store balances of borrowed tokens
                uint256 totalFlashAmount; // Variable to track total flash loan amount

                // Loop through each borrowed token to calculate balances and total flash loan amount
                for (uint256 i; i < borrowedLength; i++) {
                    address token = borrowedTokens[i];
                    uint256 borrowedAmount = IVenusPool(token)
                        .borrowBalanceStored(_vault); // Get the current borrowed balance for the token
                    underlying[i] = IVenusPool(token).underlying(); // Get the underlying asset for the borrowed token
                    tokenBalance[i] =
                        (borrowedAmount * _portfolioTokenAmount) /
                        _totalSupply; // Calculate the portion of the debt to repay
                    totalFlashAmount += repayData._flashLoanAmount[i]; // Accumulate the total flash loan amount
                }

                // Get the pool address for the flash loan
                address _poolAddress = IThena(repayData._factory).poolByPair(
                    repayData._token0,
                    repayData._token1
                );
                address flashLaonToken = repayData._flashLoanToken;
                address token0 = repayData._token0;
                address token1 = repayData._token1;

                // Prepare the flash loan data to be used in the flash loan callback
                FunctionParameters.FlashLoanData
                    memory flashData = FunctionParameters.FlashLoanData({
                        flashLoanToken: flashLaonToken,
                        debtToken: underlying,
                        protocolTokens: borrowedTokens,
                        solverHandler: repayData._solverHandler,
                        flashLoanAmount: repayData._flashLoanAmount,
                        debtRepayAmount: tokenBalance,
                        firstSwapData: repayData.firstSwapData,
                        secondSwapData: repayData.secondSwapData
                    });

                // Initiate the flash loan from the Algebra pool
                IAlgebraPool(_poolAddress).flash(
                    address(this), // Recipient of the flash loan
                    token0 == flashLaonToken ? totalFlashAmount : 0, // Amount of token0 to flash loan
                    token1 == flashLaonToken ? totalFlashAmount : 0, // Amount of token1 to flash loan
                    abi.encode(flashData) // Encode flash loan data to pass to the callback
                );
            }
        }
    }

    /**
     * @notice Handles the repayment of the vault's debt using a flash loan.
     * @param repayData Data required for the repayment process.
     */
    function repayVault(
        FunctionParameters.RepayParams calldata repayData
    ) external onlyRebalancerContract {
        // Getting pool address dynamically based on the token pair
        address _poolAddress = IThena(repayData._factory).poolByPair(
            repayData._token0,
            repayData._token1
        );

        // Defining the data to be passed in the flash loan, including the amount and pool key
        FunctionParameters.FlashLoanData memory flashData = FunctionParameters
            .FlashLoanData({
                flashLoanToken: repayData._flashLoanToken,
                debtToken: repayData._debtToken,
                protocolTokens: repayData._protocolToken,
                solverHandler: repayData._solverHandler,
                flashLoanAmount: repayData._flashLoanAmount,
                debtRepayAmount: repayData._debtRepayAmount,
                firstSwapData: repayData.firstSwapData,
                secondSwapData: repayData.secondSwapData
            });

        // Initiate the flash loan from the Algebra pool
        IAlgebraPool(_poolAddress).flash(
            address(this), // Recipient of the flash loan
            repayData._token0 == repayData._flashLoanToken
                ? repayData._flashLoanAmount[0]
                : 0, // Amount of token0 to flash loan
            repayData._token1 == repayData._flashLoanToken
                ? repayData._flashLoanAmount[0]
                : 0, // Amount of token1 to flash loan
            abi.encode(flashData) // Encode flash loan data to pass to the callback
        );
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
            FunctionParameters.TokenBalances memory tokenBalances
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

        uint256 amountOwed = totalFlashAmount + fee0; // Calculate the amount owed including the fee
        TransferHelper.safeTransfer(
            flashData.flashLoanToken,
            msg.sender,
            amountOwed
        ); // Transfer the amount owed back to the lender
        //Need Dust Transfer
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
