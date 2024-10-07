// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ErrorLibrary } from "../../library/ErrorLibrary.sol";
import { IProtocolConfig } from "../../config/protocol/IProtocolConfig.sol";
import { IAssetHandler } from "../interfaces/IAssetHandler.sol";
import { FunctionParameters } from "../../FunctionParameters.sol";

/// @title TokenBalanceLibrary
/// @notice A library for efficient token balance management and calculation in DeFi protocols
/// @dev This library optimizes gas usage by caching controller data for borrowable tokens
library TokenBalanceLibrary {
    /// @notice Struct to cache controller-specific data
    struct ControllerData {
        address controller;
        uint256 unusedCollateralPercentage;
    }

    /// @notice Fetches the balances of multiple tokens from a single vault
    function getTokenBalancesOf(
        address[] memory portfolioTokens,
        address _vault,
        IProtocolConfig _protocolConfig
    ) public view returns (uint256[] memory vaultBalances) {
        uint256 portfolioLength = portfolioTokens.length;
        vaultBalances = new uint256[](portfolioLength);
        // Create a cache to store controller data, potentially reducing external calls
        ControllerData[] memory controllerDataCache = new ControllerData[](portfolioLength);
        uint256 cacheSize = 0;

        // Iterate through all tokens and get their balances
        for (uint256 i = 0; i < portfolioLength; i++) {
            vaultBalances[i] = _getTokenBalanceOf(
                portfolioTokens[i],
                _vault,
                _protocolConfig,
                controllerDataCache,
                cacheSize
            );
        }
    }

    /// @notice Fetches the balance of a single token from the vault (non-cached version)
    function _getTokenBalanceOf(
        address _token,
        address _vault,
        IProtocolConfig _protocolConfig
    ) public view returns (uint256) {
        if (_token == address(0) || _vault == address(0))
            revert ErrorLibrary.InvalidAddress();

        // For non-borrowable tokens, simply return the balance
        if (!_protocolConfig.isBorrowableToken(_token)) {
            return IERC20Upgradeable(_token).balanceOf(_vault);
        }

        // For borrowable tokens, we need to calculate the investible balance
        address controller = _protocolConfig.marketControllers(_token);
        address assetHandler = _protocolConfig.assetHandlers(_token);
        // Get account data from the asset handler
        (FunctionParameters.AccountData memory accountData, ) = 
            IAssetHandler(assetHandler).getUserAccountData(_vault, controller);

        // Calculate the unused collateral percentage
        uint256 unusedCollateralPercentage = calculateUnusedCollateralPercentage(accountData);
        // Get the raw balance of the token
        uint256 rawBalance = IERC20Upgradeable(_token).balanceOf(_vault);
        // Adjust the balance based on the unused collateral percentage
        return (rawBalance * unusedCollateralPercentage) / 1e18;
    }

    /// @notice Fetches the balance of a single token from the vault (cached version)
    function _getTokenBalanceOf(
        address _token,
        address _vault,
        IProtocolConfig _protocolConfig,
        ControllerData[] memory controllerDataCache,
        uint256 cacheSize
    ) private view returns (uint256) {
        if (_token == address(0) || _vault == address(0))
            revert ErrorLibrary.InvalidAddress();

        // For non-borrowable tokens, simply return the balance
        if (!_protocolConfig.isBorrowableToken(_token)) {
            return IERC20Upgradeable(_token).balanceOf(_vault);
        }

        // For borrowable tokens, use cached data if available
        address controller = _protocolConfig.marketControllers(_token);
        uint256 unusedCollateralPercentage = getOrUpdateControllerData(
            controller,
            _vault,
            _protocolConfig,
            controllerDataCache,
            cacheSize
        );

        // Get the raw balance of the token
        uint256 rawBalance = IERC20Upgradeable(_token).balanceOf(_vault);
        // Adjust the balance based on the unused collateral percentage
        return (rawBalance * unusedCollateralPercentage) / 1e18;
    }

    /// @notice Retrieves or updates controller data in the cache
    function getOrUpdateControllerData(
        address controller,
        address _vault,
        IProtocolConfig _protocolConfig,
        ControllerData[] memory controllerDataCache,
        uint256 cacheSize
    ) private view returns (uint256) {
        // Check if controller data is already cached
        for (uint256 i = 0; i < cacheSize; i++) {
            if (controllerDataCache[i].controller == controller) {
                return controllerDataCache[i].unusedCollateralPercentage;
            }
        }

        // If not cached, calculate and cache the data
        address assetHandler = _protocolConfig.assetHandlers(controller);
        (FunctionParameters.AccountData memory accountData, ) = 
            IAssetHandler(assetHandler).getUserAccountData(_vault, controller);
        
        uint256 unusedCollateralPercentage = calculateUnusedCollateralPercentage(accountData);

        // Add to cache if there's space
        if (cacheSize < controllerDataCache.length) {
            controllerDataCache[cacheSize] = ControllerData({
                controller: controller,
                unusedCollateralPercentage: unusedCollateralPercentage
            });
            // Note: cacheSize is not incremented here, it should be managed by the calling function
        }

        return unusedCollateralPercentage;
    }

    /// @notice Calculates the unused collateral percentage
    function calculateUnusedCollateralPercentage(FunctionParameters.AccountData memory accountData) 
        private 
        pure 
        returns (uint256) 
    {
        // If there's no collateral, return 100% as unused
        if (accountData.totalCollateral == 0) return 1e18;
        
        // Calculate the percentage of collateral that's not being used to back debt
        // The result is scaled by 1e18 for precision
        return ((accountData.totalCollateral - accountData.totalDebt) * 1e18) / accountData.totalCollateral;
    }
}