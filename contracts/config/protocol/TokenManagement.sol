// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {ErrorLibrary} from "../../library/ErrorLibrary.sol";
import {OwnableCheck} from "./OwnableCheck.sol";
import {IPriceOracle} from "../../oracle/IPriceOracle.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/Initializable.sol";

/**
 * @title TokenManagement
 * @dev This contract manages the registry of tokens that are allowed to interact with the platform.
 * It ensures that only tokens with verified price information and approved by the platform owner can be used,
 * enhancing the platform's security and reliability.
 */
abstract contract TokenManagement is OwnableCheck, Initializable {
  // Interface instance for accessing the price oracle.
  IPriceOracle private priceOracle;

  // Mapping to track the tokens that are enabled for interaction on the platform.
  mapping(address => bool) public isEnabled;

  // Mapping to track the borrowed tokens that are enabled for interaction on the platform.
  mapping(address => bool) public isBorrowableToken;

  // Event emitted when tokens are enabled.
  event TokensEnabled(address[] tokens);

  // Event emitted when a token is disabled.
  event TokenDisabled(address indexed token);

  /**
   * @notice Initializes the contract with the price oracle address.
   * @param _priceOracle Address of the price oracle contract.
   */
  function __TokenManagement_init(
    address _priceOracle
  ) internal onlyInitializing {
    if (_priceOracle == address(0)) revert ErrorLibrary.InvalidOracleAddress();
    priceOracle = IPriceOracle(_priceOracle);
  }

  /**
   * @notice Checks whether a token is enabled for interaction on the platform.
   * @param _token Address of the token to check.
   * @return True if the token is enabled, otherwise false.
   */
  function isTokenEnabled(address _token) external view returns (bool) {
    return isEnabled[_token];
  }

  /**
   * @notice Enables a list of tokens for interaction on the platform, subject to oracle price verification.
   * Can only be called by the protocol owner.
   * @param _tokens Array of token addresses to be enabled.
   */
  function enableTokens(address[] calldata _tokens) external onlyProtocolOwner {
    uint256 tokensLength = _tokens.length;
    for (uint256 i; i < tokensLength; i++) {
      address token = _tokens[i];
      if (token == address(0)) revert ErrorLibrary.InvalidTokenAddress();
      // Ensures token has a valid price in the price oracle before enabling
      if (!(priceOracle.convertToUSD18Decimals(token, 1 ether) > 0))
        revert ErrorLibrary.TokenNotInPriceOracle();

      isEnabled[token] = true;
    }
    emit TokensEnabled(_tokens);
  }

  /**
   * @notice Disables a token from interaction on the platform. Can only be called by the protocol owner.
   * @param _token Address of the token to be disabled.
   */
  function disableToken(address _token) external onlyProtocolOwner {
    if (_token == address(0)) revert ErrorLibrary.InvalidAddress();
    isEnabled[_token] = false;
    emit TokenDisabled(_token);
  }

  /**
   * @dev Enables a list of protocol tokens for interaction on the platform.
   *
   * This function allows the protocol owner to mark specific tokens as enabled,
   * making them valid for interaction within the platform. Any token address provided
   * must not be the zero address.
   *
   * @param _borrowableTokens An array of addresses representing the borrowed tokens to be enabled.
   *
   * Requirements:
   * - Can only be called by the protocol owner (`onlyProtocolOwner`).
   * - Each token address in the `_protocolTokens` array must be non-zero.
   *
   * Reverts:
   * - If any token address in the `_protocolTokens` array is the zero address, the function will revert with `ErrorLibrary.InvalidTokenAddress()`.
   */
  function enableBorrowableTokens(
    address[] memory _borrowableTokens
  ) external onlyProtocolOwner {
    uint256 tokensLength = _borrowableTokens.length;
    for (uint256 i; i < tokensLength; i++) {
      address token = _borrowableTokens[i];
      if (token == address(0)) revert ErrorLibrary.InvalidTokenAddress();
      isBorrowableToken[token] = true;
    }
  }

  /**
   * @dev Disables a list of protocol tokens, removing them from interaction on the platform.
   *
   * This function allows the protocol owner to mark specific tokens as disabled,
   * preventing them from being used in interactions within the platform.
   *
   * @param _borrowableTokens An array of addresses representing the protocol tokens to be disabled.
   *
   * Requirements:
   * - Can only be called by the protocol owner (`onlyProtocolOwner`).
   */
  function disableBorrowableTokens(
    address[] memory _borrowableTokens
  ) external onlyProtocolOwner {
    uint256 tokensLength = _borrowableTokens.length;
    for (uint256 i; i < tokensLength; i++) {
      address token = _borrowableTokens[i];
      isBorrowableToken[token] = false;
    }
  }
}
