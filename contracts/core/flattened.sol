// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17 >=0.6.0 ^0.8.0 ^0.8.1 ^0.8.17 ^0.8.2;

// contracts/access/AccessRoles.sol

/**
 * @title AccessRoles
 * @dev Defines roles for access control in the system.
 * This contract stores constants for role identifiers used across the system to manage permissions and access.
 * Roles are used in conjunction with an AccessControl mechanism to secure functions and actions.
 */
contract AccessRoles {
  // Role for managing indices, including creating, updating, and deleting them.
  bytes32 internal constant PORTFOLIO_MANAGER_ROLE =
    keccak256("PORTFOLIO_MANAGER_ROLE");

  // Role for the highest level of administrative access, capable of managing roles and critical system settings.
  bytes32 internal constant SUPER_ADMIN = keccak256("SUPER_ADMIN");

  // Admin role for managing the whitelist, specifically capable of adding or removing addresses from the whitelist.
  bytes32 internal constant WHITELIST_MANAGER_ADMIN =
    keccak256("WHITELIST_MANAGER_ADMIN");

  // Role for managing assets, including tasks such as adjusting asset allocations and managing asset listings.
  bytes32 internal constant ASSET_MANAGER = keccak256("ASSET_MANAGER");

  // Role for managing the whitelist, typically including adding or removing addresses to/from a whitelist for access control.
  bytes32 internal constant WHITELIST_MANAGER = keccak256("WHITELIST_MANAGER");

  // Admin role for asset managers, capable of assigning or revoking the ASSET_MANAGER to other addresses.
  bytes32 internal constant ASSET_MANAGER_ADMIN =
    keccak256("ASSET_MANAGER_ADMIN");

  // Specialized role for the rebalancing contract.
  bytes32 internal constant REBALANCER_CONTRACT =
    keccak256("REBALANCER_CONTRACT");

  // Role for addresses authorized to mint tokens, typically used in token generation events or for reward distributions.
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
}

// contracts/config/protocol/IProtocolConfig.sol

/**
 * @title IProtocolConfig
 * @notice Interface for the protocol configuration contract, managing various system settings and functionalities.
 */
interface IProtocolConfig {
  // ----- OracleManagement Functions -----

  /**
   * @notice Updates the address of the price oracle.
   * @param _newOracle The address of the new price oracle.
   */
  function updatePriceOracle(address _newOracle) external;

  /**
   * @notice Returns the address of the current price oracle.
   * @return The address of the current price oracle.
   */
  function oracle() external view returns (address);

  // ----- TreasuryManagement Functions -----

  /**
   * @notice Updates the address of the Velvet treasury.
   * @param _newVelvetTreasury The address of the new Velvet treasury.
   */
  function updateVelvetTreasury(address _newVelvetTreasury) external;

  /**
   * @notice Returns the address of the Velvet treasury.
   * @return The address of the Velvet treasury.
   */
  function velvetTreasury() external view returns (address);

  // ----- SystemSettings Functions -----

  /**
   * @notice Returns the cooldown period for certain protocol operations.
   * @return The cooldown period.
   */
  function cooldownPeriod() external view returns (uint256);

  /**
   * @notice Returns the asset limit for the protocol.
   * @return The asset limit.
   */
  function assetLimit() external view returns (uint256);

  /**
   * @notice Returns the minimum initial portfolio amount.
   * @return The minimum initial portfolio amount.
   */
  function minInitialPortfolioAmount() external view returns (uint256);

  /**
   * @notice Returns the minimum portfolio token holding amount.
   * @return The minimum portfolio token holding amount.
   */
  function minPortfolioTokenHoldingAmount() external view returns (uint256);

  /**
   * @notice Returns whether the protocol is currently paused.
   * @return True if the protocol is paused, false otherwise.
   */
  function isProtocolPaused() external view returns (bool);

  /**
   * @notice Returns whether the protocol is currently in an emergency paused state.
   * @return True if the protocol is in an emergency paused state, false otherwise.
   */
  function isProtocolEmergencyPaused() external view returns (bool);

  /**
   * @notice Sets a new cooldown period for certain protocol operations.
   * @param _newCooldownPeriod The new cooldown period.
   */
  function setCoolDownPeriod(uint256 _newCooldownPeriod) external;

  /**
   * @notice Sets a new asset limit for the protocol.
   * @param _newLimit The new asset limit.
   */
  function setAssetLimit(uint256 _newLimit) external;

  /**
   * @notice Sets the pause state of the protocol.
   * @param _paused The new pause state.
   */
  function setProtocolPause(bool _paused) external;

  /**
   * @notice Sets the emergency pause state of the protocol.
   * @param _paused The new emergency pause state.
   */
  function setEmergencyPause(bool _paused) external;

  // ----- TokenManagement Functions -----

  /**
   * @notice Enables a list of tokens for the protocol.
   * @param _tokens The list of token addresses to enable.
   */
  function enableTokens(address[] calldata _tokens) external;

  /**
   * @notice Disables a specific token for the protocol.
   * @param _token The address of the token to disable.
   */
  function disableToken(address _token) external;

  /**
   * @notice Checks if a specific token is enabled.
   * @param _token The address of the token to check.
   * @return True if the token is enabled, false otherwise.
   */
  function isTokenEnabled(address _token) external view returns (bool);

  // ----- FeeManagement Functions -----

  /**
   * @notice Updates the protocol fee.
   * @param _newProtocolFee The new protocol fee.
   */
  function updateProtocolFee(uint256 _newProtocolFee) external;

  /**
   * @notice Updates the protocol streaming fee.
   * @param _newProtocolStreamingFee The new protocol streaming fee.
   */
  function updateProtocolStreamingFee(
    uint256 _newProtocolStreamingFee
  ) external;

  /**
   * @notice Returns the maximum management fee.
   * @return The maximum management fee.
   */
  function maxManagementFee() external view returns (uint256);

  /**
   * @notice Returns the maximum performance fee.
   * @return The maximum performance fee.
   */
  function maxPerformanceFee() external view returns (uint256);

  /**
   * @notice Returns the maximum entry fee.
   * @return The maximum entry fee.
   */
  function maxEntryFee() external view returns (uint256);

  /**
   * @notice Returns the maximum exit fee.
   * @return The maximum exit fee.
   */
  function maxExitFee() external view returns (uint256);

  /**
   * @notice Returns the protocol fee.
   * @return The protocol fee.
   */
  function protocolFee() external view returns (uint256);

  /**
   * @notice Returns the protocol streaming fee.
   * @return The protocol streaming fee.
   */
  function protocolStreamingFee() external view returns (uint256);

  /**
   * @notice Maximum allowed buffer unit used to slightly increase the amount of collateral to sell, expressed in 0.001% (100000 = 100%)
   * @return Max collateral buffer unit
   */
  function MAX_COLLATERAL_BUFFER_UNIT() external view returns (uint256);

  // ----- SolverManagement Functions -----

  /**
   * @notice Checks if a specific address is a solver.
   * @param _handler The address to check.
   * @return True if the address is a solver, false otherwise.
   */
  function isSolver(address _handler) external view returns (bool);

  /**
   * @notice Enables a solver handler.
   * @param _handler The address of the solver handler to enable.
   */
  function enableSolverHandler(address _handler) external;

  /**
   * @notice Disables a solver handler.
   * @param _handler The address of the solver handler to disable.
   */
  function disableSolverHandler(address _handler) external;

  /**
   * @notice Checks if a specific solver handler is enabled.
   * @param _handler The address to check.
   * @return True if the solver handler is enabled, false otherwise.
   */
  function isSolverHandlerEnabled(
    address _handler
  ) external view returns (bool);

  function whitelistLimit() external view returns (uint256);

  function allowedDustTolerance() external view returns (uint256);

  // ----- RewardTargetManagement Functions -----
  /**
   * @notice Checks if a reward target address is enabled.
   * @param _rewardTargetAddress The address of the reward target to check.
   * @return Boolean indicating if the reward target address is enabled.
   */
  function isRewardTargetEnabled(
    address _rewardTargetAddress
  ) external view returns (bool);

  /**
   * @notice Enables a reward target address by setting its status to true in the mapping.
   * @dev This function can only be called by the protocol owner.
   * @param _rewardTargetAddress The address of the reward target to enable.
   * @dev Reverts if the provided address is invalid (address(0)).
   */
  function enableRewardTarget(address _rewardTargetAddress) external;

  /**
   * @notice Disables a reward target address by setting its status to false in the mapping.
   * @dev This function can only be called by the protocol owner.
   * @param _rewardTargetAddress The address of the reward target to disable.
   * @dev Reverts if the provided address is invalid (address(0)).
   */
  function disableRewardTarget(address _rewardTargetAddress) external;

  function positionWrapperBaseImplementation() external view returns (address);

  function allowedRatioDeviationBps() external view returns (uint256);

  function acceptedSlippageFeeReinvestment() external view returns (uint256);

  function marketControllers(address _asset) external view returns (address);

  function assetHandlers(address _asset) external view returns (address);

  function getSupportedControllers() external view returns (address[] memory);

  function isSupportedControllers(
    address _controllers
  ) external view returns (bool);

  function isBorrowableToken(address _asset) external view returns (bool);

  function isSupportedFactory(
    address _factoryAddress
  ) external view returns (bool);

  function MAX_BORROW_TOKEN_LIMIT() external pure returns(uint256);
}

// contracts/core/calculations/MathUtils.sol

/**
 * @title MathUtils
 * @notice Provides utility functions for common mathematical operations.
 * @dev This library offers functions for operations like finding the minimum
 *      and maximum values between two numbers. It can be extended to include
 *      more complex mathematical functions as needed.
 */
library MathUtils {
  error InvalidCastToUint128();
  error InvalidCastToUint160();

  /**
   * @notice Returns the smaller of two numbers.
   * @param _a The first number to compare.
   * @param _b The second number to compare.
   * @return The smaller of the two numbers.
   */
  function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }

  /**
   * @notice Returns the larger of two numbers.
   * @param _a The first number to compare.
   * @param _b The second number to compare.
   * @return The larger of the two numbers.
   */
  function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a > _b ? _a : _b;
  }

  /**
   * @notice Subtracts two numbers, returning zero if the result would be negative.
   * @param _a The number from which to subtract.
   * @param _b The number to subtract from the first number.
   * @return The result of the subtraction or zero if it would be negative.
   */
  function _subOrZero(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a > _b) {
      unchecked {
        return _a - _b;
      }
    } else {
      return 0;
    }
  }

  /**
   * @notice Safely casts a uint value to uint128, ensuring the value is within the range of uint160.
   * @param _val The value to cast to uint128.
   * @return The value cast to uint128, if it is representable.
   * @dev Reverts with `InvalidCastToUint128` error if the value exceeds the maximum uint128 value.
   */
  function safe128(uint _val) internal pure returns (uint128) {
    if (_val > type(uint128).max) revert InvalidCastToUint128();
    return uint128(_val);
  }

  /**
   * @notice Safely casts a uint value to uint160, ensuring the value is within the range of uint160.
   * @param _val The value to cast to uint160.
   * @return The value cast to uint160, if it is representable.
   * @dev Reverts with `InvalidCastToUint160` error if the value exceeds the maximum uint160 value.
   */
  function safe160(uint _val) internal pure returns (uint160) {
    if (_val > type(uint160).max) revert InvalidCastToUint160();
    return uint160(_val);
  }
}

// contracts/core/interfaces/IEIP712.sol

interface IEIP712 {
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// contracts/core/interfaces/ITokenExclusionManager.sol

interface ITokenExclusionManager {
  function init(
    address _accessController,
    address _protocolConfig,
    address _baseTokenRemovalVaultImplementation
  ) external;

  function snapshot() external returns (uint256);

  function _currentSnapshotId() external view returns (uint256);

  function claimRemovedTokens(
    address user,
    uint256 startId,
    uint256 endId
  ) external;

  function setUserRecord(address _user, uint256 _userBalance) external;

  function setTokenAndSupplyRecord(
    uint256 _snapShotId,
    address _tokenRemoved,
    address _vault,
    uint256 _totalSupply
  ) external;

  function claimTokenAtId(address user, uint256 id) external;

  function getDataAtId(
    address user,
    uint256 id
  ) external view returns (bool, uint256);

  function userRecord(
    address user,
    uint256 snapshotId
  ) external view returns (uint256 portfolioBalance, bool hasInteractedWithId);

  function deployTokenRemovalVault() external returns (address);

  function removedToken(
    uint256 id
  ) external view returns (address token, address vault, uint256 totalSupply);
}

// contracts/fee/IFeeModule.sol

interface IFeeModule {
  /**
   * @dev Initializes the fee module, setting up the required configurations.
   * @param _portfolio The address of the Portfolio contract.
   * @param _assetManagementConfig The address of the AssetManagementConfig contract.
   * @param _protocolConfig The address of the ProtocolConfig contract.
   * @param _accessController The address of the AccessController contract.
   */
  function init(
    address _portfolio,
    address _assetManagementConfig,
    address _protocolConfig,
    address _accessController
  ) external;

  /**
   * @dev Charges and mints protocol and management fees based on current configurations and token supply.
   * Can only be called by the portfolio manager.
   */
  function chargeProtocolAndManagementFeesProtocol() external;

  /**
   * @dev Calculates and mints performance fees based on the vault's performance relative to a high watermark.
   * Can only be called by the asset manager when the protocol is not in emergency pause.
   */
  function chargeProtocolAndManagementFees() external;

  /**
   * @dev Charges entry or exit fees based on a specified percentage, adjusting the mint amount accordingly.
   * @param _mintAmount The amount being minted or burned, subject to entry/exit fees.
   * @param _fee The fee percentage to apply.
   * @return userAmount The amount after fees have been deducted.
   */
  function _chargeEntryOrExitFee(
    uint256 _mintAmount,
    uint256 _fee
  ) external returns (uint256);

  /**
   * @notice Returns the timestamp of the last protocol fee charged.
   * @return The timestamp of the last protocol fee charged.
   */
  function lastChargedProtocolFee() external view returns (uint256);

  /**
   * @notice Returns the timestamp of the last management fee charged.
   * @return The timestamp of the last management fee charged.
   */
  function lastChargedManagementFee() external view returns (uint256);

  /**
   * @dev Function to update the high watermark for performance fee calculation.
   * @param _currentPrice Current price of the portfolio token in USD.
   */
  function updateHighWaterMark(uint256 _currentPrice) external;

  /**
   * @notice Resets the high watermark for the portfolio to zero.
   * @dev This function can only be called by the portfolio manager. The high watermark represents the highest value
   * the portfolio has reached and is used for calculating performance fees. Resetting it to zero can be used for
   * specific scenarios, such as the start of a new performance period.
   */
  function resetHighWaterMark() external;

  function highWatermark() external view returns (uint256);

  function managementFee() external view returns (uint256);

  function performanceFee() external view returns (uint256);

  function entryFee() external view returns (uint256);

  function exitFee() external view returns (uint256);
}

// contracts/library/ErrorLibrary.sol

/**
 * @title ErrorLibrary
 * @author Velvet.Capital
 * @notice This is a library contract including custom defined errors
 */

library ErrorLibrary {
  /// @notice Thrown when caller is not rebalancer contract
  error CallerNotRebalancerContract();
  /// @notice Thrown when caller is not asset manager
  error CallerNotAssetManager();
  /// @notice Thrown when caller is not asset manager
  error CallerNotSuperAdmin();
  /// @notice Thrown when caller is not whitelist manager
  error CallerNotWhitelistManager();
  /// @notice Thrown when length of tokens array is zero
  error InvalidLength();
  /// @notice Thrown when user is not allowed to deposit
  error UserNotAllowedToDeposit();
  /// @notice Thrown when portfolio token in not initialized
  error PortfolioTokenNotInitialized();
  /// @notice Thrown when caller is not holding enough portfolio token amount to withdraw
  error CallerNotHavingGivenPortfolioTokenAmount();
  /// @notice Thrown when the tokens are already initialized
  error AlreadyInitialized();
  /// @notice Thrown when the token is not whitelisted
  error TokenNotWhitelisted();
  /// @notice Thrown when token address being passed is zero
  error InvalidTokenAddress();
  /// @notice Thrown when transfer is prohibited
  error Transferprohibited();
  /// @notice Thrown when caller is not portfolio manager
  error CallerNotPortfolioManager();
  /// @notice Thrown when offchain handler is not valid
  error InvalidSolver();
  /// @notice Thrown when set time period is not over
  error TimePeriodNotOver();
  /// @notice Thrown when trying to set any fee greater than max allowed fee
  error InvalidFee();
  /// @notice Thrown when zero address is passed for treasury
  error ZeroAddressTreasury();
  /// @notice Thrown when previous address is passed for treasury
  error PreviousTreasuryAddress();
  /// @notice Thrown when zero address is being passed
  error InvalidAddress();
  /// @notice Thrown when caller is not the owner
  error CallerNotOwner();
  /// @notice Thrown when protocol is not paused
  error ProtocolNotPaused();
  /// @notice Thrown when protocol is paused
  error ProtocolIsPaused();
  /// @notice Thrown when token is not enabled
  error TokenNotEnabled();
  /// @notice Thrown when portfolio creation is paused
  error PortfolioCreationIsPause();
  /// @notice Thrown when asset manager is trying to input token which already exist
  error TokenAlreadyExist();
  /// @notice Thrown when cool down period is not passed
  error CoolDownPeriodNotPassed();
  /// @notice Throws when the setup is failed in gnosis
  error ModuleNotInitialised();
  /// @notice Throws when threshold is more than owner length
  error InvalidThresholdLength();
  /// @notice Throws when no owner address is passed while fund creation
  error NoOwnerPassed();
  /// @notice Thorws when the caller does not have a default admin role
  error CallerNotAdmin();
  /// @notice Throws when a public fund is tried to made transferable only to whitelisted addresses
  error PublicFundToWhitelistedNotAllowed();
  /// @notice Generic call failed error
  error CallFailed();
  /// @notice Generic transfer failed error
  error TransferFailed();
  /// @notice Throws when the initToken or updateTokenList function of Portfolio is having more tokens than set by the Registry
  error TokenCountOutOfLimit(uint256 limit);
  /// @notice Throws when the array lenghts don't match for adding price feed or enabling tokens
  error IncorrectArrayLength();
  /// @notice Throws when user calls updateFees function before proposing a new fee
  error NoNewFeeSet();
  /// @notice Throws when sequencer is down
  error SequencerIsDown();
  /// @notice Throws when sequencer threshold is not crossed
  error SequencerThresholdNotCrossed();
  /// @notice Throws when depositAmount and depositToken length does not match
  error InvalidDepositInputLength();
  /// @notice Mint amount smaller than users indended buy amount
  error InvalidMintAmount();
  /// @notice Thorws when zero price is set for min portfolio price
  error InvalidMinPortfolioAmount();
  /// @notice Thorws when min portfolio price is set less then min portfolio price set by protocol
  error InvalidMinPortfolioAmountByAssetManager();
  /// @notice Throws when assetManager set zero or less initial portfolio price then set by protocol
  error InvalidInitialPortfolioAmount();
  /// @notice Throws when zero amount or amount less then protocol minPortfolioAmount is set while updating min Portfolio amount by assetManager
  error InvalidMinPortfolioTokenHoldingAmount();
  /// @notice Throws when assetmanager set min portfolio amount less then acceptable amount set by protocol
  error InvalidMinAmountByAssetManager();
  /// @notice Throws when user is not maintaining min portfolio token amount while withdrawing
  error CallerNeedToMaintainMinTokenAmount();
  /// @notice Throws when user minted amount during deposit is less then set by assetManager
  error MintedAmountIsNotAccepted();
  /// @notice Throws when balance of buyToken after rebalance is zero
  error BalanceOfVaultCannotNotBeZero(address);
  /// @notice Throws when balance of selltoken in handler after swap is not zero
  error BalanceOfHandlerShouldBeZero();
  /// @notice Throws when balance of selltoken in handler after swap is exceeding dust
  error BalanceOfHandlerShouldNotExceedDust();
  /// @notice Throws when balance of selltoken in vault after swap is exceeding dust
  error BalanceOfVaultShouldNotExceedDust();
  /// @notice Throws when swap return value in handler is less then min buy amounts
  error ReturnValueLessThenExpected();
  /// @notice Throws when non portfolio token balance in not zero after rebalance
  error NonPortfolioTokenBalanceIsNotZero();
  /// @notice Throws when the oracle price is not updated under set timeout
  error PriceOracleExpired();
  /// @notice Throws when the oracle price is returned 0
  error PriceOracleInvalid();
  /// @notice Thrown when oracle address is zero address
  error InvalidOracleAddress();
  /// @notice Thrown when token is not in price oracle
  error TokenNotInPriceOracle();
  /// @notice Throws when token is not removed and user is trying to claim
  error NoTokensRemoved();
  /// @notice Throws when assetManager tries to remove portfolioToken
  error IsPortfolioToken();
  /// @notice Throws when disabled tokens are used in protocol
  error NotPortfolioToken();
  /// @notice Thrown when balance of vault is zero
  error BalanceOfVaultIsZero();
  /// @notice Thrown when max asset limit is set zero
  error InvalidAssetLimit();
  /// @notice Thrown when max whitelist limit is set zero
  error InvalidWhitelistLimit();
  /// @notice Thrown when withdrawal amount is too small and tokenBalance in return is zero
  error WithdrawalAmountIsSmall();
  /// @notice Thrown when deposit amount is zero
  error AmountCannotBeZero();
  // @notice Thrown when percentage of token to remove is invalid
  error InvalidTokenRemovalPercentage();
  // @notice Thrown when user passes the wrong buy token list (not equal to buy tokens in calldata)
  error InvalidBuyTokenList();
  /// @notice Thrown when permitted to wrong spender
  error InvalidSpender();
  /// @notice Thrown when claiming reward tokens failed
  error ClaimFailed();
  /// @notice Thrown when protocol owner passed invalid protocol streaming fee
  error InvalidProtocolStreamingFee();
  /// @notice Thrown when protocol owner passed invalid protocol fee
  error InvalidProtocolFee();
  /// @notice Thrown when protocol is emergency paused
  error ProtocolEmergencyPaused();
  /// @notice Thrown when batchHandler balance diff is zero
  error InvalidBalanceDiff();
  ///@notice Error thrown when the user tries to withdraw or transfer an amount greater than their balance.
  error InsufficientBalance();
  // @notice Thrown when an unpause action is attempted too soon after the last unpause.
  error TimeSinceLastUnpauseNotElapsed();
  // @notice Thrown when an invalid cooldown period is set.
  error InvalidCooldownPeriod();
  // @notice Thrown when the division by zero occurs
  error DivisionByZero();
  // @notice Thrown when the token whitelist length is zero
  error InvalidTokenWhitelistLength();
  // @notice Thrown when the reward target is not enabled
  error RewardTargetNotEnabled();
  // @notice Thrown when the allowance is insufficient
  error InsufficientAllowance();
  // @notice Thrown when user tries to claim for invalid Id
  error InvalidId();
  // @notice Thrown when exemption does match token to withdraw
  error InvalidExemptionTokens();
  // @notice Thrown when exemption tokens length is greater then portfolio tokens length
  error InvalidExemptionTokensLength();
  // @notice Thrown when the dust tolerance input is invalid
  error InvalidDustTolerance();
  // @notice Thrown when the target address is not whitelisted
  error InvalidTargetAddress();
  // @notice Thrown when the ETH balance sent is zero
  error InvalidBalance();
  // @notice Thrown when the swap amount is invalid
  error InvalidSwapAmount();
  // @notice Thrown when the passed deviation bps is invalid
  error InvalidDeviationBps();
  // @notice Thrown when external position management is not whitelisted
  error ExternalPositionManagementNotWhitelisted();
  // @notice Thrown when the increase liquidity call fails
  error IncreaseLiquidityFailed();
  // @notice Thrown when the decrease liquidity call fails
  error DecreaseLiquidityFailed();
  // @notice Thrown when borrow failed
  error BorrowFailed();
  // @notice Thrown when invalid flashloan provider factory address is provided
  error InvalidFactoryAddress();
  // @notice Thrown when buffer unit is more then max valid collateral buffer unit
  error InvalidBufferUnit();
  // @notice Thrown when new buffer unit is more then max accetable buffer unit
  error InvalidNewBufferUnit();
  /// @notice Thrown when a swap operation is invalid
  error InvalidSwap();
  // @notice Thrown when controller data is not found
  error ControllerDataNotFound();
  // @notice Thrown when the input token used for swapping is invalid
  error InvalidSwapToken();
  // @notice Thrown when protocol owner sets new borrow token limit more then max limit(20)
  error ExceedsBorrowLimit();
  // @notice Thrown when borrow token limit exceeds the max limit set by protocol owner
  error BorrowTokenLimitExceeded();
  // @notice Thrown when flash loan functionality is not active for the portfolio
  error FlashLoanIsInactive();
}

// contracts/vault/IVelvetSafeModule.sol

interface IVelvetSafeModule {
  function transferModuleOwnership(address newOwner) external;

  /// @dev Initialize function, will be triggered when a new proxy is deployed
  /// @param initializeParams Parameters of initialization encoded
  function setUp(bytes memory initializeParams) external;

  function executeWallet(
    address handlerAddresses,
    bytes calldata encodedCalls
  ) external returns (bool, bytes memory);
}

// node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable_0 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/interfaces/IERC1967Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/interfaces/draft-IERC1822Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/proxy/beacon/IBeaconUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/token/ERC20/IERC20Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable_1 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/utils/AddressUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/utils/StorageSlotUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// node_modules/@uniswap/lib/contracts/libraries/TransferHelper.sol

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// contracts/core/calculations/TokenCalculations.sol

/**
 * @title TokenCalculations
 * @dev Provides utility functions for calculating token amounts and ratios in the context of portfolio funds.
 * This contract contains pure functions that are essential for determining the minting amounts for new deposits
 * and calculating the proportionate share of a deposit within the vault. It is utilized by the main
 * portfolio fund contract to facilitate user deposits and withdrawals.
 */

contract TokenCalculations {
  // A constant representing the conversion factor from ETH to WEI, facilitating calculations with token amounts.
  uint256 internal constant ONE_ETH_IN_WEI = 10 ** 18;

  /**
   * @notice Calculates the amount of portfolio tokens to mint based on the user's deposit share and total supply.
   * @dev This function is crucial for determining the correct amount of portfolio tokens a user receives upon deposit,
   * taking into account the existing total supply of portfolio tokens.
   * @param _userShare The proportionate deposit amount in WEI the user is making into the fund.
   * @param _totalSupply The current total supply of portfolio tokens in the fund.
   * @return The amount of portfolio tokens that should be minted for the user's deposit.
   */
  function _calculateMintAmount(
    uint256 _userShare,
    uint256 _totalSupply
  ) internal pure returns (uint256) {
    uint256 remainingShare = ONE_ETH_IN_WEI - _userShare;
    if (remainingShare == 0) revert ErrorLibrary.DivisionByZero();
    return (_userShare * _totalSupply) / remainingShare;
  }

  /**
   * @notice Calculates the ratio of an deposit amount to the total token balance in the vault.
   * @dev This helper function computes the ratio of a user's deposit to the total holdings of a specific token
   * in the vault, facilitating proportional deposits and withdrawals.
   * @param depositAmount The amount of a specific token the user wishes to deposit, in WEI.
   * @param tokenBalance The total balance of that specific token currently held in the vault.
   * @return The deposit ratio, scaled to 18 decimal places to maintain precision.
   */
  function _getDepositToVaultBalanceRatio(
    uint256 depositAmount,
    uint256 tokenBalance
  ) internal pure returns (uint256) {
    if (tokenBalance == 0) revert ErrorLibrary.BalanceOfVaultIsZero();

    // Calculate the deposit ratio to 18 decimal precision
    return (depositAmount * ONE_ETH_IN_WEI) / tokenBalance;
  }
}

// contracts/core/interfaces/IAllowanceTransfer.sol

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer is IEIP712 {
  /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
  event NonceInvalidation(
    address indexed owner,
    address indexed token,
    address indexed spender,
    uint48 newNonce,
    uint48 oldNonce
  );

  /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
  event Approval(
    address indexed owner,
    address indexed token,
    address indexed spender,
    uint160 amount,
    uint48 expiration
  );

  /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
  event Permit(
    address indexed owner,
    address indexed token,
    address indexed spender,
    uint160 amount,
    uint48 expiration,
    uint48 nonce
  );

  /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
  event Lockdown(
    address indexed owner,
    address indexed token,
    address indexed spender
  );

  /// @notice The permit data for a token
  struct PermitDetails {
    // ERC20 token address
    address token;
    // the maximum amount allowed to spend
    uint160 amount;
    // timestamp at which a spender's token allowances become invalid
    uint48 expiration;
    // an incrementing value indexed per owner,token,and spender for each signature
    uint48 nonce;
  }

  /// @notice The permit message signed for a single token allowance
  struct PermitSingle {
    // the permit data for a single token alownce
    PermitDetails details;
    // address permissioned on the allowed tokens
    address spender;
    // deadline on the permit signature
    uint256 sigDeadline;
  }

  /// @notice The permit message signed for multiple token allowances
  struct PermitBatch {
    // the permit data for multiple token allowances
    PermitDetails[] details;
    // address permissioned on the allowed tokens
    address spender;
    // deadline on the permit signature
    uint256 sigDeadline;
  }

  /// @notice The saved permissions
  /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
  /// @dev Setting amount to type(uint160).max sets an unlimited approval
  struct PackedAllowance {
    // amount allowed
    uint160 amount;
    // permission expiry
    uint48 expiration;
    // an incrementing value indexed per owner,token,and spender for each signature
    uint48 nonce;
  }

  /// @notice A token spender pair.
  struct TokenSpenderPair {
    // the token the spender is approved
    address token;
    // the spender address
    address spender;
  }

  /// @notice Details for a token transfer.
  struct AllowanceTransferDetails {
    // the owner of the token
    address from;
    // the recipient of the token
    address to;
    // the amount of the token
    uint160 amount;
    // the token to be transferred
    address token;
  }

  /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
  /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
  /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
  function allowance(
    address user,
    address token,
    address spender
  ) external view returns (uint160 amount, uint48 expiration, uint48 nonce);

  /// @notice Approves the spender to use up to amount of the specified token up until the expiration
  /// @param token The token to approve
  /// @param spender The spender address to approve
  /// @param amount The approved amount of the token
  /// @param expiration The timestamp at which the approval is no longer valid
  /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
  /// @dev Setting amount to type(uint160).max sets an unlimited approval
  function approve(
    address token,
    address spender,
    uint160 amount,
    uint48 expiration
  ) external;

  /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
  /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
  /// @param owner The owner of the tokens being approved
  /// @param permitSingle Data signed over by the owner specifying the terms of approval
  /// @param signature The owner's signature over the permit data
  function permit(
    address owner,
    PermitSingle memory permitSingle,
    bytes calldata signature
  ) external;

  /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
  /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
  /// @param owner The owner of the tokens being approved
  /// @param permitBatch Data signed over by the owner specifying the terms of approval
  /// @param signature The owner's signature over the permit data
  function permit(
    address owner,
    PermitBatch memory permitBatch,
    bytes calldata signature
  ) external;

  /// @notice Transfer approved tokens from one address to another
  /// @param from The address to transfer from
  /// @param to The address of the recipient
  /// @param amount The amount of the token to transfer
  /// @param token The token address to transfer
  /// @dev Requires the from address to have approved at least the desired amount
  /// of tokens to msg.sender.
  function transferFrom(
    address from,
    address to,
    uint160 amount,
    address token
  ) external;

  /// @notice Transfer approved tokens in a batch
  /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
  /// @dev Requires the from addresses to have approved at least the desired amount
  /// of tokens to msg.sender.
  function transferFrom(
    AllowanceTransferDetails[] calldata transferDetails
  ) external;

  /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
  /// by batch revoking approvals
  /// @param approvals Array of approvals to revoke.
  function lockdown(TokenSpenderPair[] calldata approvals) external;

  /// @notice Invalidate nonces for a given (token, spender) pair
  /// @param token The token to invalidate nonces for
  /// @param spender The spender to invalidate nonces for
  /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
  /// @dev Can't invalidate more than 2**16 nonces per transaction.
  function invalidateNonces(
    address token,
    address spender,
    uint48 newNonce
  ) external;
}

// node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable_0 is IERC20Upgradeable_0 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/Initializable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/token/ERC20/extensions/IERC20MetadataUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable_1 is IERC20Upgradeable_1 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// contracts/core/cooldown/CooldownManager.sol

/**
 * @title CooldownManager
 * @dev Manages cooldown periods for depositors to impose restrictions on rapid deposit and withdrawal actions.
 * This contract tracks the timestamps of users' last deposits and applies cooldown periods to mitigate
 * the risks associated with quick, speculative trading, and to ensure the stability of the fund.
 */
contract CooldownManager {
  // Maps an address to its last deposit timestamp to enforce cooldown periods.
  mapping(address => uint256) public userLastDepositTime;
  // Maps an address to its last withdrawal cooldown timestamp to enforce withdrawal restrictions.
  mapping(address => uint256) public userCooldownPeriod;

  /**
   * @dev Calculates the cooldown period to be applied to an depositor after making a deposit.
   * The cooldown mechanism is designed to discourage immediate withdrawals after deposits, encouraging longer-term deposit by imposing a waiting period.
   *
   * @param _currentUserBalance The current balance of the depositor's tokens in the pool, representing their share of the deposit.
   * @param _mintedLiquidity The amount of liquidity (in terms of pool tokens) that will be minted for the depositor as a result of the deposit.
   * @param _defaultCooldownTime  The predefined cooldown duration set by the protocol, representing the minimum time an depositor must wait before making a withdrawal.
   * @param _oldCooldownTime The cooldown time previously applied to the depositor, factoring in any past deposits.
   * @param _lastDepositTimestamp The timestamp of the depositor's last deposit, used to calculate the remaining cooldown time.
   * @return cooldown The new cooldown time to be applied to the depositor's account, calculated based on their current and newly minted balances, as well as the protocol's cooldown settings.
   */
  function _calculateCooldownPeriod(
    uint256 _currentUserBalance,
    uint256 _mintedLiquidity,
    uint256 _defaultCooldownTime,
    uint256 _oldCooldownTime,
    uint256 _lastDepositTimestamp
  ) internal view returns (uint256 cooldown) {
    uint256 prevCooldownEnd = _lastDepositTimestamp + _oldCooldownTime;
    // Calculate remaining cooldown from previous deposit, if any.
    uint256 prevCooldownRemaining = MathUtils._subOrZero(
      prevCooldownEnd,
      block.timestamp
    );

    // If the depositor's current balance is zero (new depositor or fully withdrawn), apply full cooldown for new liquidity, unless minting zero liquidity.
    if (_currentUserBalance == _mintedLiquidity) {
      cooldown = _mintedLiquidity == 0 ? 0 : _defaultCooldownTime;
    } else if (
      _mintedLiquidity == 0 || _defaultCooldownTime < prevCooldownRemaining
    ) {
      // If no new liquidity is minted or if the current cooldown is less than remaining, apply the remaining cooldown.
      cooldown = prevCooldownRemaining;
    } else {
      // Calculate average cooldown based on the proportion of existing and new liquidity.
      uint256 balanceBeforeMint = _currentUserBalance - _mintedLiquidity;
      uint256 averageCooldown = (_mintedLiquidity *
        _defaultCooldownTime +
        balanceBeforeMint *
        prevCooldownRemaining) / _currentUserBalance;
      // Ensure the cooldown does not exceed the current cooldown setting and is at least 1 second.
      cooldown = averageCooldown > _defaultCooldownTime
        ? _defaultCooldownTime
        : MathUtils._max(averageCooldown, 1);
    }
  }

  /**
   * @notice Verifies if a user's cooldown period has passed and if they are eligible to perform the next action.
   * @dev Throws an error if the cooldown period has not yet passed, enforcing the restriction.
   * @param _user The address of the user to check the cooldown period for.
   */
  function _checkCoolDownPeriod(address _user) internal view {
    uint256 userCoolDownPeriod = userLastDepositTime[_user] +
      userCooldownPeriod[_user];
    uint256 remainingCoolDown = userCoolDownPeriod <= block.timestamp
      ? 0
      : userCoolDownPeriod - block.timestamp;

    if (remainingCoolDown > 0) {
      revert ErrorLibrary.CoolDownPeriodNotPassed();
    }
  }
}

// contracts/wrappers/abstract/IPositionWrapper.sol

/**
 * @title IPositionWrapper
 * @dev Interface for the PositionWrapper contract, which encapsulates Uniswap V3 positions as tradable ERC20 tokens.
 * This interface allows interaction with a PositionWrapper contract, enabling operations such as initialization,
 * minting, and burning of tokens, along with access to associated token data.
 */
interface IPositionWrapper is IERC20Upgradeable_0, IERC20MetadataUpgradeable_0 {
  /**
   * @notice Initializes the contract with Uniswap V3 position tokens and ERC20 token details.
   * @param _token0 Address of the first token in the Uniswap V3 pair.
   * @param _token1 Address of the second token in the Uniswap V3 pair.
   * @param _name Name of the ERC20 token representing the position.
   * @param _symbol Symbol of the ERC20 token representing the position.
   * @dev This function is typically called once to configure the token pair and metadata for the ERC20 representation.
   */
  function init(
    address _positionManager,
    address _token0,
    address _token1,
    string memory _name,
    string memory _symbol
  ) external;

  function setIntitialParameters(
    uint24 _fee,
    int24 _tickLower,
    int24 _tickUpper
  ) external;

  /**
   * @notice Sets the token ID of the Uniswap V3 position after initializing the contract.
   * @param _tokenId The unique identifier of the Uniswap V3 position.
   */
  function setTokenId(uint256 _tokenId) external;

  /**
   * @notice Mints ERC20 tokens representing a proportional share of the Uniswap V3 position.
   * @param to The address to receive the minted tokens.
   * @param amount The quantity of tokens to mint.
   */
  function mint(address to, uint256 amount) external;

  /**
   * @notice Burns ERC20 tokens to decrease the representation of the underlying Uniswap V3 position.
   * @param from The address from which the tokens will be burned.
   * @param amount The quantity of tokens to burn.
   */
  function burn(address from, uint256 amount) external;

  /**
   * @notice Updates the token ID associated with the ERC20 tokens, typically during adjustments in the position.
   * @param _tokenId The new Uniswap V3 position ID.
   */
  function updateTokenId(uint256 _tokenId) external;

  /**
   * @notice Retrieves the token ID of the Uniswap V3 position.
   * @return The Uniswap V3 position ID.
   */
  function tokenId() external returns (uint256);

  /**
   * @notice Returns the address of the first token in the Uniswap V3 pair.
   * @return Address of the first token.
   */
  function token0() external returns (address);

  /**
   * @notice Returns the address of the second token in the Uniswap V3 pair.
   * @return Address of the second token.
   */
  function token1() external returns (address);

  /**
   * @notice Indicates whether the initial minting has been performed.
   * @return Boolean status of initial mint completion.
   */
  function initialMint() external returns (bool);

  function initialFee() external returns (uint24);

  function initialTickLower() external returns (int24);

  function initialTickUpper() external returns (int24);

  function positionManager() external returns (address);
}

// node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/security/ReentrancyGuardUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/utils/ContextUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// contracts/core/user/UserManagement.sol

/**
 * @title UserManagement
 * @dev Provides functionalities related to managing user-specific states within the platform,
 * such as tracking deposit times and managing withdrawal cooldown periods. This contract
 * interacts with the TokenExclusionManager to update user records during deposit and
 * withdrawal operations.
 */
contract UserManagement is Initializable {
  // Mapping to track the last time a user made an deposit. This is used to enforce any cooldowns or restrictions on new deposits.
  mapping(address => uint256) public _lastDepositTime;

  // Mapping to track the cooldown period after a user makes a withdrawal. This is used to restrict the frequency of withdrawals.
  mapping(address => uint256) public _lastWithdrawCooldown;

  // Reference to the TokenExclusionManager contract which manages token-specific rules and user records related to deposits and withdrawals.
  ITokenExclusionManager public tokenExclusionManager;

  /**
   * @dev Initializes the UserManagement contract with a reference to the TokenExclusionManager contract.
   * @param _tokenExclusionManager The address of the TokenExclusionManager contract.
   */
  function __UserManagement_init(
    address _tokenExclusionManager
  ) internal onlyInitializing {
    tokenExclusionManager = ITokenExclusionManager(_tokenExclusionManager);
  }

  /**
   * @dev Updates the user's record in the TokenExclusionManager. This includes the user's current balance
   * after an deposit or withdrawal operation has occurred.
   * @param _user The address of the user whose record is being updated.
   * @param _userBalance The new balance of the user after the operation.
   */
  function _updateUserRecord(address _user, uint256 _userBalance) internal {
    tokenExclusionManager.setUserRecord(_user, _userBalance);
  }

  // Reserved storage gap to accommodate potential future layout adjustments.
  uint256[49] private __uint256GapUserManagement;
}

// contracts/oracle/IPriceOracle.sol

interface IPriceOracle {
  function WETH() external returns (address);

  function _addFeed(
    address base,
    address quote,
    AggregatorV2V3Interface aggregator
  ) external;

  function convertToUSD18Decimals(
    address _base,
    uint256 amountIn
  ) external view returns (uint256 amountOut);
}

// contracts/wrappers/WrapperFunctionParameters.sol

/**
 * @title WrapperFunctionParameters
 * @dev Library defining structured parameters for functions in wrapper contracts,
 * aiding in organized handling of data for position management operations.
 */
library WrapperFunctionParameters {
  /**
   * @dev Struct for parameters used during the minting of a new position in a liquidity pool.
   * It encapsulates all necessary details for position creation and initial liquidity provision.
   * @param _amount0Desired Desired amount of token0 to be added to the position.
   * @param _amount1Desired Desired amount of token1 to be added to the position.
   * @param _amount0Min Minimum acceptable amount of token0 ensuring slippage protection.
   * @param _amount1Min Minimum acceptable amount of token1 ensuring slippage protection.
   * @param _fee Fee tier of the pool, represented in basis points.
   * @param _tickLower Lower bound of the price tick range for the position.
   * @param _tickUpper Upper bound of the price tick range for the position.
   */
  struct PositionMintParams {
    uint256 _amount0Desired;
    uint256 _amount1Desired;
    uint256 _amount0Min;
    uint256 _amount1Min;
    uint24 _fee;
    int24 _tickLower;
    int24 _tickUpper;
  }

  /**
   * @dev Struct for initial parameters used when minting tokens related to a liquidity position.
   * This is typically used for first-time position setup where specific pool parameters are not yet set.
   * @param _amount0Desired Desired initial amount of token0.
   * @param _amount1Desired Desired initial amount of token1.
   * @param _amount0Min Minimum acceptable amount of token0 to mitigate slippage.
   * @param _amount1Min Minimum acceptable amount of token1 to mitigate slippage.
   */
  struct InitialMintParams {
    uint256 _amount0Desired;
    uint256 _amount1Desired;
    uint256 _amount0Min;
    uint256 _amount1Min;
  }

  /**
   * @dev Extension of PositionMintParams for specific use cases or additional functionality
   * that may require different handling or additional parameters.
   * @param _amount0Desired Desired amount of token0 for the position.
   * @param _amount1Desired Desired amount of token1 for the position.
   * @param _amount0Min Minimum amount of token0 required to avoid transaction slippage.
   * @param _amount1Min Minimum amount of token1 required to avoid transaction slippage.
   * @param _tickLower Lower tick boundary for setting the price range.
   * @param _tickUpper Upper tick boundary for setting the price range.
   */
  struct PositionMintParamsThena {
    uint256 _amount0Desired;
    uint256 _amount1Desired;
    uint256 _amount0Min;
    uint256 _amount1Min;
    int24 _tickLower;
    int24 _tickUpper;
  }

  /**
   * @dev Parameters required for a deposit operation, typically including token amounts and address details for returning any excess tokens.
   * @param _dustReceiver Address to which any non-utilized tokens ('dust') are returned.
   * @param _positionWrapper Reference to the position wrapper contract.
   * @param _amount0Desired Desired amount of token0 to add to the position.
   * @param _amount1Desired Desired amount of token1 to add to the position.
   * @param _amount0Min Minimum amount of token0 to protect against slippage.
   * @param _amount1Min Minimum amount of token1 to protect against slippage.
   * @param _tokenIn Address of the token being input in case of a swap.
   * @param _tokenOut Address of the token being output from the swap.
   * @param _amountIn Amount of the input token to be swapped.
   */
  struct WrapperDepositParams {
    address _dustReceiver;
    IPositionWrapper _positionWrapper;
    uint256 _amount0Desired;
    uint256 _amount1Desired;
    uint256 _amount0Min;
    uint256 _amount1Min;
    address _tokenIn;
    address _tokenOut;
    uint256 _amountIn;
  }

  /**
   * @dev Struct defining parameters for a swap operation within a liquidity management context,
   * including the positions, tokens, amounts, and price ticks involved.
   * @param _positionWrapper Wrapper contract associated with the position.
   * @param _tokenId Identifier of the position token.
   * @param _amountIn Amount of the token to be swapped.
   * @param _token0 First token of the liquidity pair.
   * @param _token1 Second token of the liquidity pair.
   * @param _tokenIn Token being swapped.
   * @param _tokenOut Token to receive from the swap.
   * @param _tickLower Lower price tick for managing the position range.
   * @param _tickUpper Upper price tick for managing the position range.
   */
  struct SwapParams {
    IPositionWrapper _positionWrapper;
    uint256 _tokenId;
    uint256 _amountIn;
    address _token0;
    address _token1;
    address _tokenIn;
    address _tokenOut;
    int24 _tickLower;
    int24 _tickUpper;
  }
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/access/OwnableUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// contracts/wrappers/abstract/IPositionManager.sol

/**
 * @title IPositionManager
 * @dev Interface for a Position Manager contract that coordinates interactions
 * between Uniswap V3 positions and external systems like asset management or access control.
 * This interface facilitates the initialization of position manager instances, updating base
 * implementations for position wrappers, and querying wrapped positions.
 */
interface IPositionManager {
  /**
   * @notice Initializes the Position Manager with configuration settings.
   * @dev Sets up the position manager with necessary configurations including
   * asset management settings, access control, and a base implementation for position wrappers.
   * @param _assetManagerConfig Address of the asset management configuration contract.
   * @param _accessController Address of the access control contract.
   */
  function init(
    address _protocolConfig,
    address _assetManagerConfig,
    address _accessController,
    address _nftManager,
    address _swapRouter
  ) external;

  /**
   * @notice Updates the base implementation address for position wrappers.
   * @dev This allows the position manager to adapt to new wrapper implementations without disrupting existing positions.
   * Useful in upgrading the system or correcting issues in previous implementations.
   * @param _positionWrapperBaseImplementation The new base implementation address to be used for creating position wrappers.
   */
  function updatePositionWrapperBaseImplementation(
    address _positionWrapperBaseImplementation
  ) external;

  /**
   * @notice Checks if a given address is a recognized and valid wrapped position.
   * @dev This function is typically used to verify if a particular contract address corresponds
   * to a valid position wrapper managed by this system, ensuring that interactions are limited
   * to legitimate and tracked wrappers.
   * @return bool Returns true if the address corresponds to a wrapped position, false otherwise.
   */
  function isWrappedPosition(address) external returns (bool);

  function initializePositionAndDeposit(
    address _dustReceiver,
    IPositionWrapper _positionWrapper,
    WrapperFunctionParameters.InitialMintParams memory params
  ) external;

  /**
   * @notice Increases liquidity in an existing Uniswap V3 position and mints corresponding wrapper tokens.
   * @param _params Struct containing parameters necessary for adding liquidity and minting tokens.
   * @dev Handles the transfer of tokens, adds liquidity to Uniswap V3, and mints wrapper tokens proportionate to the added liquidity.
   */
  function increaseLiquidity(
    WrapperFunctionParameters.WrapperDepositParams memory _params
  ) external;

  /**
   * @notice Decreases liquidity for an existing Uniswap V3 position and burns the corresponding wrapper tokens.
   * @param _positionWrapper Address of the position wrapper contract.
   * @param _withdrawalAmount Amount of wrapper tokens representing the liquidity to be removed.
   * @param _amount0Min Minimum amount of token0 expected to prevent slippage.
   * @param _amount1Min Minimum amount of token1 expected to prevent slippage.
   * @param tokenIn The address of the token to be swapped (input).
   * @param tokenOut The address of the token to be received (output).
   * @param amountIn The amount of `tokenIn` to be swapped to `tokenOut`.
   * @dev Burns wrapper tokens and reduces liquidity in the Uniswap V3 position based on the provided parameters.
   */
  function decreaseLiquidity(
    address _positionWrapper,
    uint256 _withdrawalAmount,
    uint256 _amount0Min,
    uint256 _amount1Min,
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external;

  /**
   * @notice Function to retrieve the asset management configuration contract address.
   * @return The address of the asset management configuration contract.
   */
  function assetManagementConfig() external view returns (address);

  /**
   * @notice Function to retrieve the protocol configuration contract address.
   * @return The address of the protocol configuration contract.
   */
  function protocolConfig() external view returns (address);
}

// contracts/FunctionParameters.sol

/**
 * @title FunctionParameters
 * @notice A library for defining structured data passed across functions in DeFi protocols.
 * @dev This library encapsulates various structures used for initializing, configuring, and managing on-chain financial products.
 */
library FunctionParameters {
  /**
   * @notice Struct for initializing a new PortfolioFactory
   * @dev Encapsulates data necessary for deploying an PortfolioFactory and associated components.
   * @param _basePortfolioAddress Base Portfolio contract address for cloning
   * @param _baseTokenExclusionManagerAddress Base Token Exclusion address for cloning
   * @param _baseRebalancingAddress Base Rebalancing module address for cloning
   * @param _baseAssetManagementConfigAddress Base AssetManagement Config address for cloning
   * @param _feeModuleImplementationAddress Fee Module implementation contract address
   * @param  _baseTokenRemovalVaultImplementation Token Removal Vault implementation contract address
   * @param  _basePositionManager Position manager implementation contract address
   * @param _baseVelvetGnosisSafeModuleAddress Base Gnosis-Safe module address for cloning
   * @param  _basePositionManager Position manager implementation contract address
   * @param _gnosisSingleton Gnosis Singleton contract address
   * @param _gnosisFallbackLibrary Gnosis Fallback Library address
   * @param _gnosisMultisendLibrary Gnosis Multisend Library address
   * @param _gnosisSafeProxyFactory Gnosis Safe Proxy Factory address
   * @param _protocolConfig Protocol configuration contract address
   * @param _velvetProtocolFee Protocol fee percentage (in basis points)
   */
  struct PortfolioFactoryInitData {
    address _basePortfolioAddress;
    address _baseTokenExclusionManagerAddress;
    address _baseRebalancingAddres;
    address _baseAssetManagementConfigAddress;
    address _feeModuleImplementationAddress;
    address _baseTokenRemovalVaultImplementation;
    address _baseVelvetGnosisSafeModuleAddress;
    address _basePositionManager;
    address _baseBorrowManager;
    address _gnosisSingleton;
    address _gnosisFallbackLibrary;
    address _gnosisMultisendLibrary;
    address _gnosisSafeProxyFactory;
    address _protocolConfig;
  }

  /**
   * @notice Data for initializing the Portfolio module
   * @dev Used when setting up a new Portfolio instance.
   * @param _name Name of the Portfolio Fund
   * @param _symbol Symbol of the Portfolio Fund
   * @param _vault Vault address associated with the Portfolio Fund
   * @param _module Safe module address associated with the Portfolio Fund
   * @param _accessController Access Controller address for managing roles
   * @param _protocolConfig Protocol configuration contract address
   * @param _assetManagementConfig Asset Management configuration contract address
   * @param _feeModule Fee Module contract address
   */
  struct PortfolioInitData {
    string _name;
    string _symbol;
    address _vault;
    address _module;
    address _tokenExclusionManager;
    address _borrowManager;
    address _accessController;
    address _protocolConfig;
    address _assetManagementConfig;
    address _feeModule;
  }

  /**
   * @notice Data for initializing a new Portfolio Fund via the Factory
   * @dev Encapsulates settings and configurations for a newly created Portfolio Fund.
   * @param _assetManagerTreasury Treasury address for asset manager fee accumulation
   * @param _whitelistedTokens Array of token addresses permitted in the Portfolio Fund
   * @param _managementFee Management fee (annual, in basis points)
   * @param _performanceFee Performance fee (upon profit, in basis points)
   * @param _entryFee Fee for entering the fund (in basis points)
   * @param _exitFee Fee for exiting the fund (in basis points)
   * @param _initialPortfolioAmount Initial amount of the portfolio token
   * @param _minPortfolioTokenHoldingAmount Minimum amount of portfolio tokens that can be held and can be minted
   * @param _public Indicates if the fund is open to the public
   * @param _transferable Indicates if the fund's tokens are transferable
   * @param _transferableToPublic Indicates if the fund's tokens are transferable to the public
   * @param _whitelistTokens Indicates if only whitelisted tokens can be included in the fund
   * @param _name Name of the Portfolio Fund
   * @param _symbol Symbol of the Portfolio Fund
   */
  struct PortfolioCreationInitData {
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    uint256 _initialPortfolioAmount;
    uint256 _minPortfolioTokenHoldingAmount;
    bool _public;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
    bool _externalPositionManagementWhitelisted;
    string _name;
    string _symbol;
  }

  /**
   * @notice Data for initializing the Asset Manager Config
   * @dev Used for setting up asset management configurations for an Portfolio Fund.
   * @param _managementFee Annual management fee (in basis points)
   * @param _performanceFee Performance fee (upon profit, in basis points)
   * @param _entryFee Entry fee (in basis points)
   * @param _exitFee Exit fee (in basis points)
   * @param _initialPortfolioAmount Initial amount of the portfolio token
   * @param _minPortfolioTokenHoldingAmount Minimum amount of portfolio tokens that can be held and can be minted
   * @param _protocolConfig Protocol configuration contract address
   * @param _accessController Access Controller contract address
   * @param _assetManagerTreasury Treasury address for asset manager fee accumulation
   * @param _whitelistedTokens Array of token addresses permitted in the Portfolio Fund
   * @param _publicPortfolio Indicates if the portfolio is open to public deposits
   * @param _transferable Indicates if the portfolio's tokens are transferable
   * @param _transferableToPublic Indicates if the portfolio's tokens are transferable to the public
   * @param _whitelistTokens Indicates if only whitelisted tokens can be included in the portfolio
   */
  struct AssetManagementConfigInitData {
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    uint256 _initialPortfolioAmount;
    uint256 _minPortfolioTokenHoldingAmount;
    address _protocolConfig;
    address _accessController;
    address _feeModule;
    address _assetManagerTreasury;
    address _basePositionManager;
    address _nftManager;
    address _swapRouterV3;
    address[] _whitelistedTokens;
    bool _publicPortfolio;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
    bool _externalPositionManagementWhitelisted;
  }

  /**
   * @notice Data structure for setting up roles during Portfolio Fund creation
   * @dev Used for assigning roles to various components of the Portfolio Fund ecosystem.
   * @param _portfolio Portfolio contract address
   * @param _protocolConfig Protocol configuration contract address
   * @param _portfolioCreator Address of the portfolio creator
   * @param _rebalancing Rebalancing module contract address
   * @param _feeModule Fee Module contract address
   */
  struct AccessSetup {
    address _portfolio;
    address _portfolioCreator;
    address _rebalancing;
    address _feeModule;
    address _borrowManager;
  }

  /**
   * @dev Struct containing the parameters required for repaying a debt using a flash loan.
   *
   * @param _factory The address of the factory contract responsible for creating necessary contracts.
   * @param _token0 The address of the first token in the swap pair (e.g., USDT).
   * @param _token1 The address of the second token in the swap pair (e.g., USDC).
   * @param _flashLoanToken The address of the token to be borrowed in the flash loan.
   * @param _debtToken The addresses of the tokens representing the debt to be repaid.
   * @param _protocolToken The addresses of the protocol-specific tokens, such as lending tokens (e.g., vTokens for Venus protocol).
   * @param _solverHandler The address of the contract handling the execution of swaps and other logic.
   * @param _bufferUnit Buffer unit for collateral amount
   * @param _flashLoanAmount The amounts of the flash loan to be taken for each corresponding `_flashLoanToken`.
   * @param _debtRepayAmount The amounts of debt to be repaid for each corresponding `_debtToken`.
   * @param firstSwapData The encoded data for the first swap operation, used for repaying the debt.
   * @param secondSwapData The encoded data for the second swap operation, used for further adjustments after repaying the debt.
   * @param isMaxRepayment Boolean flag to determine if the maximum borrowed amount should be repaid.
   */
  struct RepayParams {
    address _factory;
    address _token0; //USDT
    address _token1; //USDC
    address _flashLoanToken;
    address[] _debtToken;
    address[] _protocolToken; // lending token in case of venus
    address _solverHandler;
    uint256 _bufferUnit;
    uint256[] _flashLoanAmount;
    uint256[] _debtRepayAmount;
    bytes[] firstSwapData;
    bytes[] secondSwapData;
    bool isMaxRepayment;
  }

  /**
   * @dev Struct containing the parameters required for withdrawing and repaying debt using a flash loan.
   *
   * @param _factory The address of the factory contract responsible for creating necessary contracts.
   * @param _token0 The address of the first token in the swap pair.
   * @param _token1 The address of the second token in the swap pair.
   * @param _flashLoanToken The address of the token to be borrowed in the flash loan.
   * @param _solverHandler The address of the contract handling the execution of swaps and other logic.
   * @param _bufferUnit Buffer unit for collateral amount
   * @param _flashLoanAmount The amounts of the flash loan to be taken for each corresponding `_flashLoanToken`.
   * @param firstSwapData The encoded data for the first swap operation, used in the process of repaying or withdrawing.
   * @param secondSwapData The encoded data for the second swap operation, used for further adjustments after the first swap.
   */
  struct withdrawRepayParams {
    address _factory;
    address _token0;
    address _token1;
    address _flashLoanToken;
    address _solverHandler;
    uint256 _bufferUnit;
    uint256[] _flashLoanAmount;
    bytes[] firstSwapData;
    bytes[] secondSwapData;
  }

  /**
   * @dev Struct containing detailed data for executing a flash loan and managing debt repayment.
   *
   * @param flashLoanToken The address of the token to be borrowed in the flash loan.
   * @param debtToken The addresses of the tokens representing the debt to be repaid.
   * @param protocolTokens The addresses of the protocol-specific tokens, such as lending tokens (e.g., vTokens for Venus protocol).
   * @param solverHandler The address of the contract handling the execution of swaps and other logic.
   * @param bufferUnit Buffer unit for collateral amount
   * @param flashLoanAmount The amounts of the flash loan to be taken for each corresponding `flashLoanToken`.
   * @param debtRepayAmount The amounts of debt to be repaid for each corresponding `debtToken`.
   * @param firstSwapData The encoded data for the first swap operation, used for repaying the debt.
   * @param secondSwapData The encoded data for the second swap operation, used for further adjustments after repaying the debt.
   * @param isMaxRepayment Boolean flag to determine if the maximum borrowed amount should be repaid.
   */
  struct FlashLoanData {
    address flashLoanToken;
    address[] debtToken;
    address[] protocolTokens;
    address solverHandler;
    address poolAddress;
    uint256 bufferUnit;
    uint256[] flashLoanAmount;
    uint256[] debtRepayAmount;
    bytes[] firstSwapData;
    bytes[] secondSwapData;
    bool isMaxRepayment;
  }

  /**
   * @dev Struct containing account-related data such as collateral, debt, and health factors.
   *
   * @param totalCollateral The total collateral value of the account.
   * @param totalDebt The total debt value of the account.
   * @param availableBorrows The total amount available for borrowing.
   * @param currentLiquidationThreshold The current liquidation threshold value of the account.
   * @param ltv The loan-to-value ratio of the account.
   * @param healthFactor The health factor of the account, used to determine its risk of liquidation.
   */
  struct AccountData {
    uint totalCollateral;
    uint totalDebt;
    uint availableBorrows;
    uint currentLiquidationThreshold;
    uint ltv;
    uint healthFactor;
  }

  /**
   * @dev Struct containing arrays of token addresses related to lending and borrowing activities.
   *
   * @param lendTokens The array of addresses for tokens that are used in lending operations.
   * @param borrowTokens The array of addresses for tokens that are used in borrowing operations.
   */
  struct TokenAddresses {
    address[] lendTokens;
    address[] borrowTokens;
  }

  /**
   * @notice Struct for defining a rebalance intent
   * @dev Encapsulates the intent data for performing a rebalance operation.
   * @param _newTokens Array of new token addresses to be included in the Portfolio Fund
   * @param _sellTokens Array of token addresses to be sold during the rebalance
   * @param _sellAmounts Corresponding amounts of each token to sell
   * @param _handler Address of the intent handler for executing rebalance
   * @param _callData Encoded call data for the rebalance operation
   */
  struct RebalanceIntent {
    address[] _newTokens;
    address[] _sellTokens;
    uint256[] _sellAmounts;
    address _handler;
    bytes _callData;
  }

  /**
   * @notice Struct of batchHandler data
   * @dev Encapsulates the data needed to batch transaction.
   * @param _minMintAmount The minimum amount of portfolio tokens the user expects to receive for their deposit, protecting against slippage
   * @param _depositAmount Amount to token to swap to vailt tokens
   * @param _target Adress of portfolio contract to deposit
   * @param _depositToken Address of token that needed to be swapped
   * @param _callData Encoded call data for swap operation
   */
  struct BatchHandler {
    uint256 _minMintAmount;
    uint256 _depositAmount;
    address _target;
    address _depositToken;
    bytes[] _callData;
  }

  /**
   * @dev Struct to encapsulate the parameters required for deploying a Safe and its associated modules.
   * @param _gnosisSingleton Address of the Safe singleton contract.
   * @param _gnosisSafeProxyFactory Address of the Safe Proxy Factory contract.
   * @param _gnosisMultisendLibrary Address of the Multisend library contract.
   * @param _gnosisFallbackLibrary Address of the Fallback library contract.
   * @param _baseGnosisModule Address of the base module to be used.
   * @param _owners Array of addresses to be designated as owners of the Safe.
   * @param _threshold Number of owner signatures required to execute a transaction in the Safe.
   */
  struct SafeAndModuleDeploymentParams {
    address _gnosisSingleton;
    address _gnosisSafeProxyFactory;
    address _gnosisMultisendLibrary;
    address _gnosisFallbackLibrary;
    address _baseGnosisModule;
    address[] _owners;
    uint256 _threshold;
  }

  /**
   * @notice Struct to hold parameters for managing deposits into external positions.
   * @dev This struct organizes data for performing swaps and managing liquidity in external positions.
   * @param _positionWrappers Addresses of external position wrapper contracts.
   * @param _swapTokens Tokens involved in swaps or liquidity additions.
   * @param _positionWrapperIndex Indices linking position wrappers to portfolio tokens.
   * @param _portfolioTokenIndex Indices linking swap tokens to portfolio tokens.
   * @param _index0 Indices of first tokens in liquidity pairs.
   * @param _index1 Indices of second tokens in liquidity pairs.
   * @param _amount0Min Minimum amounts for first tokens to mitigate slippage.
   * @param _amount1Min Minimum amounts for second tokens to mitigate slippage.
   * @param _isExternalPosition Booleans indicating external position involvement.
   * @param _tokenIn Input tokens for swap operations.
   * @param _tokenOut Output tokens for swap operations.
   * @param _amountIn Input amounts for swap operations.
   */
  struct ExternalPositionDepositParams {
    address[] _positionWrappers;
    address[] _swapTokens;
    uint256[] _positionWrapperIndex;
    uint256[] _portfolioTokenIndex;
    uint256[] _index0;
    uint256[] _index1;
    uint256[] _amount0Min;
    uint256[] _amount1Min;
    bool[] _isExternalPosition;
    address[] _tokenIn;
    address[] _tokenOut;
    uint256[] _amountIn;
  }

  /**
   /**
    * @title ExternalPositionWithdrawParams
    * @dev Struct to hold parameters for managing withdrawals from external positions, facilitating operations like swaps or liquidity removals.
    * This structure is crucial for coordinating interactions with external DeFi protocols, ensuring that operations proceed within predefined parameters for risk and slippage management.
    * @param _positionWrappers Array of addresses of external position wrapper contracts from which withdrawals are to be made.
    * @param _amountsMin0 Array of minimum amounts of the first token that must be received when withdrawing liquidity or performing swaps.
    * @param _amountsMin1 Array of minimum amounts of the second token that must be received, analogous to _amountsMin0.
    * @param _tokenIn Array of addresses of tokens being used as input for swap operations.
    * @param _tokenOut Array of addresses of tokens expected to be received from swap operations.
    * @param _amountIn Array of amounts of input tokens to be used in swap or withdrawal operations.
    */
  struct ExternalPositionWithdrawParams {
    address[] _positionWrappers;
    uint256[] _amountsMin0;
    uint256[] _amountsMin1;
    address[] _tokenIn;
    address[] _tokenOut;
    uint256[] _amountIn;
  }

  /**
   * @notice Struct for Enso Rebalance Params
   * @dev Encapsulates the parameters required for performing a rebalance operation using the Enso protocol.
   * @param _positionManager Address of the Enso Position Manager contract.
   * @param _to Address of the recipient for the rebalance operation.
   * @param _calldata Encoded call data for the rebalance operation.
   */
  struct EnsoRebalanceParams {
    IPositionManager _positionManager;
    address _to;
    bytes _calldata;
  }
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/token/ERC20/ERC20Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable_1, IERC20MetadataUpgradeable_1 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// contracts/access/IAccessController.sol

/**
 * @title IAccessController
 * @dev Interface for the AccessController contract to manage roles and permissions within the Portfolio platform.
 */
interface IAccessController {
  function setupRole(bytes32 _role, address _account) external;

  function setUpRoles(
    FunctionParameters.AccessSetup memory _setupData
  ) external;

  function transferSuperAdminOwnership(
    address _oldAccount,
    address _newAccount
  ) external;

  function hasRole(bytes32 role, address account) external view returns (bool);
}

// contracts/config/assetManagement/IAssetManagementConfig.sol

/**
 * @title IAssetManagementConfig
 * @notice Interface for the asset management configuration contract.
 */
interface IAssetManagementConfig {
  /**
   * @notice Initializes the asset management configuration with the provided initial data.
   * @param initData The initialization data for the asset management configuration.
   */
  function init(
    FunctionParameters.AssetManagementConfigInitData calldata initData
  ) external;

  /**
   * @notice Returns the management fee.
   * @return The management fee.
   */
  function managementFee() external view returns (uint256);

  /**
   * @notice Returns the performance fee.
   * @return The performance fee.
   */
  function performanceFee() external view returns (uint256);

  /**
   * @notice Returns the entry fee.
   * @return The entry fee.
   */
  function entryFee() external view returns (uint256);

  /**
   * @notice Returns the exit fee.
   * @return The exit fee.
   */
  function exitFee() external view returns (uint256);

  /**
   * @notice Returns the initial portfolio amount.
   * @return The initial portfolio amount.
   */
  function initialPortfolioAmount() external view returns (uint256);

  /**
   * @notice Returns the minimum portfolio token holding amount.
   * @return The minimum portfolio token holding amount.
   */
  function minPortfolioTokenHoldingAmount() external view returns (uint256);

  /**
   * @notice Returns the address of the asset manager treasury.
   * @return The address of the asset manager treasury.
   */
  function assetManagerTreasury() external returns (address);

  /**
   * @notice Returns the address of the position manager.
   * @return The address of the position manager.
   */
  function positionManager() external returns (address);

  /**
   * @notice Checks if a token is whitelisted.
   * @param token The address of the token.
   * @return True if the token is whitelisted, false otherwise.
   */
  function whitelistedTokens(address token) external returns (bool);

  /**
   * @notice Checks if a user is whitelisted.
   * @param user The address of the user.
   * @return True if the user is whitelisted, false otherwise.
   */
  function whitelistedUsers(address user) external returns (bool);

  /**
   * @notice Checks if the portfolio is public.
   * @return True if the portfolio is public, false otherwise.
   */
  function publicPortfolio() external returns (bool);

  /**
   * @notice Checks if the portfolio token is transferable.
   * @return True if the portfolio token is transferable, false otherwise.
   */
  function transferable() external returns (bool);

  /**
   * @notice Checks if the portfolio token is transferable to the public.
   * @return True if the portfolio token is transferable to the public, false otherwise.
   */
  function transferableToPublic() external returns (bool);

  /**
   * @notice Checks if token whitelisting is enabled.
   * @return True if token whitelisting is enabled, false otherwise.
   */
  function tokenWhitelistingEnabled() external returns (bool);

  /**
   * @notice Updates the initial portfolio amount.
   * @param _newPrice The new initial portfolio amount.
   */
  function updateInitialPortfolioAmount(uint256 _newPrice) external;

  /**
   * @notice Updates the minimum portfolio token holding amount.
   * @param _minPortfolioTokenHoldingAmount The new minimum portfolio token holding amount.
   */
  function updateMinPortfolioTokenHoldingAmount(
    uint256 _minPortfolioTokenHoldingAmount
  ) external;

  function isTokenWhitelisted(address _token) external returns (bool);

  function owner() external view returns (address);
}

// contracts/core/interfaces/IAssetHandler.sol

interface IAssetHandler {
  struct MultiTransaction {
    address to;
    bytes txData;
  }

  function getBalance(
    address pool,
    address asset
  ) external view returns (uint256 balance);

  function getDecimals() external pure returns (uint256 decimals);

  function enterMarket(
    address[] memory assets
  ) external pure returns (bytes memory data);

  function exitMarket(address asset) external pure returns (bytes memory data);

  function borrow(
    address pool,
    address asset,
    uint256 borrowAmount
  ) external pure returns (bytes memory data);

  function repay(
    uint256 borrowAmount
  ) external pure returns (bytes memory data);

  function approve(
    address pool,
    uint256 borrowAmount
  ) external pure returns (bytes memory data);

  function getAllProtocolAssets(
    address account,
    address comptroller
  )
    external
    view
    returns (address[] memory lendTokens, address[] memory borrowTokens);

  function getUserAccountData(
    address user,
    address comptoller
  )
    external
    view
    returns (
      FunctionParameters.AccountData memory accountData,
      FunctionParameters.TokenAddresses memory tokenBalances
    );

  function getBorrowedTokens(
    address user,
    address comptroller
  ) external view returns (address[] memory borrowedTokens);

  function getInvestibleBalance(
    address _token,
    address _vault,
    address _controller
  ) external view returns (uint256);

  function loanProcessing(
    address vault,
    address executor,
    address controller,
    address receiver,
    address[] memory lendTokens,
    uint256 totalCollateral,
    uint fee,
    FunctionParameters.FlashLoanData memory flashData
  )
    external
    view
    returns (MultiTransaction[] memory transactions, uint256 totalFlashAmount);

  function executeUserFlashLoan(
    address _vault,
    address _receiver,
    uint256 _portfolioTokenAmount,
    uint256 _totalSupply,
    address[] memory borrowedTokens,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external;

  function executeVaultFlashLoan(
    address _receiver,
    FunctionParameters.RepayParams calldata repayData
  ) external;

  function getCollateralAmountToSell(
    address _user,
    address _controller,
    address _protocolToken,
    address[] memory lendTokens,
    uint256 _debtRepayAmount,
    uint256 feeUnit,
    uint256 totalCollateral,
    uint256 bufferUnit
  ) external view returns (uint256[] memory amounts);
}

// contracts/core/interfaces/IBorrowManager.sol

interface IBorrowManager {
  function init(
    address vault,
    address protocolConfig,
    address portfolio,
    address accessController
  ) external;

  function repayBorrow(
    uint256 _portfolioTokenAmount,
    uint256 _totalSupply,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external;

  function repayVault(
    address _controller,
    FunctionParameters.RepayParams calldata repayData
  ) external returns(bool);
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// node_modules/@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/UUPSUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// contracts/core/calculations/TokenBalanceLibrary.sol

/**
 * @title Token Balance Library
 * @dev Library for managing token balances within a vault. Provides utility functions to fetch individual
 * and collective token balances from a specified vault address.
 */
library TokenBalanceLibrary {
  /**
   * @dev Struct to hold controller-specific data
   * @param controller The address of the controller
   * @param unusedCollateralPercentage The percentage of unused collateral (scaled by 1e18)
   */
  struct ControllerData {
    address controller;
    uint256 unusedCollateralPercentage;
  }

  /**
   * @notice Fetches data for all supported controllers
   * @dev Iterates through all supported controllers and calculates their unused collateral percentage
   * @param vault The address of the vault to fetch data for
   * @param _protocolConfig The protocol configuration contract
   * @return controllersData An array of ControllerData structs containing controller addresses and their unused collateral percentages
   */
  function getControllersData(
    address vault,
    IProtocolConfig _protocolConfig
  ) public view returns (ControllerData[] memory controllersData) {
    address[] memory controllers = _protocolConfig.getSupportedControllers();
    controllersData = new ControllerData[](controllers.length);

    for (uint256 i; i < controllers.length;) {
      address controller = controllers[i];
      IAssetHandler assetHandler = IAssetHandler(
        _protocolConfig.assetHandlers(controller)
      );
      (FunctionParameters.AccountData memory accountData, ) = assetHandler
        .getUserAccountData(vault, controller);

      uint256 unusedCollateralPercentage;
      if (accountData.totalCollateral == 0) {
        unusedCollateralPercentage = 1e18; // 100% unused if no collateral
      } else {
        unusedCollateralPercentage =
          ((accountData.totalCollateral - accountData.totalDebt) * 1e18) /
          accountData.totalCollateral;
      }

      controllersData[i] = ControllerData({
        controller: controller,
        unusedCollateralPercentage: unusedCollateralPercentage
      });
      unchecked { ++i; }
    }
  }

  /**
   * @notice Finds the ControllerData for a specific controller
   * @dev Iterates through the controllersData array to find the matching controller
   * @param controllersData An array of ControllerData structs to search through
   * @param controller The address of the controller to find
   * @return The ControllerData struct for the specified controller
   */
  function findControllerData(
    ControllerData[] memory controllersData,
    address controller
  ) internal pure returns (ControllerData memory) {
    for (uint256 i; i < controllersData.length;) {
      if (controllersData[i].controller == controller) {
        return controllersData[i];
      }
      unchecked { ++i; }
    }
    revert ErrorLibrary.ControllerDataNotFound();
  }

  /**
   * @notice Fetches the balances of multiple tokens from a single vault.
   * @dev Iterates through an array of token addresses to retrieve each token's balance in the vault.
   * Utilizes `_getTokenBalanceOf` to fetch each individual token balance securely and efficiently.
   *
   * @param portfolioTokens Array of ERC20 token addresses whose balances are to be fetched.
   * @param _vault The vault address from which to retrieve the balances.
   * @return vaultBalances Array of balances corresponding to the list of input tokens.
   */
  function getTokenBalancesOf(
    address[] memory portfolioTokens,
    address _vault,
    IProtocolConfig _protocolConfig
  )
    public
    view
    returns (
      uint256[] memory vaultBalances,
      ControllerData[] memory controllersData
    )
  {
    uint256 portfolioLength = portfolioTokens.length;
    vaultBalances = new uint256[](portfolioLength); // Initializes the array to hold fetched balances.

    controllersData = getControllersData(_vault, _protocolConfig);

    for (uint256 i; i < portfolioLength; ) {
      vaultBalances[i] = _getAdjustedTokenBalance(
        portfolioTokens[i],
        _vault,
        _protocolConfig,
        controllersData
      ); // Fetches balance for each token.
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Fetches the balance of a specific token held in a given vault.
   * @dev Retrieves the token balance using the ERC20 `balanceOf` function.
   * Throws if the token or vault address is zero to prevent erroneous queries.
   *
   * @param _token The address of the token whose balance is to be retrieved.
   * @param _vault The address of the vault where the token is held.
   * @return tokenBalance The current token balance within the vault.
   */
  function _getAdjustedTokenBalance(
    address _token,
    address _vault,
    IProtocolConfig _protocolConfig,
    ControllerData[] memory controllersData
  ) public view returns (uint256 tokenBalance) {
    if (_token == address(0) || _vault == address(0))
      revert ErrorLibrary.InvalidAddress(); // Ensures neither the token nor the vault address is zero.
    if (_protocolConfig.isBorrowableToken(_token)) {
      address controller = _protocolConfig.marketControllers(_token);
      ControllerData memory controllerData = findControllerData(
        controllersData,
        controller
      );

      uint256 rawBalance = _getTokenBalanceOf(_token, _vault);
      tokenBalance =
        (rawBalance * controllerData.unusedCollateralPercentage) /
        1e18;
    } else {
      tokenBalance = _getTokenBalanceOf(_token, _vault);
    }
  }
  
  /**
   * @notice Fetches the balance of a specific token held in a given vault.
   * @dev Retrieves the token balance using the ERC20 `balanceOf` function.
   *
   * @param _token The address of the token whose balance is to be retrieved.
   * @param _vault The address of the vault where the token is held.
   * @return tokenBalance The current token balance within the vault.
   */
  function _getTokenBalanceOf(
    address _token,
    address _vault
  ) public view returns (uint256 tokenBalance) {
    tokenBalance = IERC20Upgradeable_0(_token).balanceOf(_vault);
  }
}

// contracts/core/config/Dependencies.sol

// Import interfaces for various configurations and modules.

/**
 * @title Dependencies
 * @dev Abstract contract providing a framework for accessing configurations and modules across the platform.
 * This contract defines virtual functions to be implemented by inheriting contracts for accessing shared resources,
 * such as configuration settings and fee mechanisms.
 */
abstract contract Dependencies {
  /**
   * @notice Virtual function to retrieve the asset management configuration interface.
   * @dev This function should be overridden in derived contracts to return the the Portfolio Contract.
   * @return The interface of the asset management configuration contract.
   */
  function assetManagementConfig()
    public
    view
    virtual
    returns (IAssetManagementConfig);

  /**
   * @notice Virtual function to retrieve the protocol configuration interface.
   * @dev This function should be overridden in derived contracts to return the Portfolio Contract.
   * @return The interface of the protocol configuration contract.
   */
  function protocolConfig() public view virtual returns (IProtocolConfig);

  /**
   * @notice Virtual function to retrieve the fee module interface.
   * @dev This function should be overridden in derived contracts to return the Portfolio Contract.
   * @return The interface of the fee module contract.
   */
  function feeModule() public view virtual returns (IFeeModule);
}

// contracts/core/management/FeeManager.sol

// Import Dependencies to access configurations and modules.

/**
 * @title FeeManager
 * @dev Extends AccessModifiers and Dependencies to manage and execute fee-related operations within the platform.
 * Provides functionality to charge management and protocol fees, ensuring that fee operations are handled
 * securely and in accordance with platform rules.
 */
abstract contract FeeManager is Dependencies {
  /**
   * @notice Charges applicable fees by calling the fee module.
   * @dev Calls the `_chargeProtocolAndManagementFees` function of the fee module. Charges are only applied
   * if the caller is not the asset manager treasury or the protocol treasury, preventing unnecessary fee deduction
   * during internal operations.
   * This design ensures that fees are dynamically managed based on the transaction context and are only deducted
   * when appropriate, maintaining platform efficiency.
   */
  function _chargeFees(address _user) internal {
    // Check if the sender is not a treasury account to avoid charging fees on internal transfers.
    if (
      !(_user == assetManagementConfig().assetManagerTreasury() ||
        _user == protocolConfig().velvetTreasury())
    ) {
      // Invoke the fee module to charge both protocol and management fees.
      feeModule().chargeProtocolAndManagementFeesProtocol();
    }
  }
}

// contracts/core/access/AccessModifiers.sol

/**
 * @title AccessModifiers
 * @dev Provides role-based access control modifiers to restrict function execution to specific roles.
 * This abstract contract extends AccessRoles to utilize predefined role constants.
 * It is designed to be inherited by other contracts that require role-based permissions.
 */
abstract contract AccessModifiers is AccessRoles, Initializable {
  // The access controller contract instance for role verification.
  IAccessController public accessController;

  /**
   * @dev Modifier to restrict function access to only the super admin role.
   * Reverts with CallerNotSuperAdmin error if the caller does not have the SUPER_ADMIN role.
   */
  modifier onlySuperAdmin() {
    if (!_checkRole(SUPER_ADMIN, msg.sender)) {
      revert ErrorLibrary.CallerNotSuperAdmin();
    }
    _;
  }

  /**
   * @dev Modifier to restrict function access to only the portfolio manager contract.
   * Reverts with CallerNotPortfolioManager error if the caller does not have the PORTFOLIO_MANAGER_ROLE role.
   */
  modifier onlyPortfolioManager() {
    if (!_checkRole(PORTFOLIO_MANAGER_ROLE, msg.sender)) {
      //Did this so that, I can use pullFromVault/VaultInteraction in abi.encode() and execute
      revert ErrorLibrary.CallerNotPortfolioManager();
    }
    _;
  }

  /**
   * @dev Modifier to restrict function access to only the rebalancer contract.
   * Reverts with CallerNotRebalancerContract error if the caller does not have the REBALANCER_CONTRACT role.
   */
  modifier onlyRebalancerContract() {
    if (!_checkRole(REBALANCER_CONTRACT, msg.sender)) {
      revert ErrorLibrary.CallerNotRebalancerContract();
    }
    _;
  }

  /**
   * @dev Modifier to restrict function access to only entities with the minter role.
   * Reverts with CallerNotPortfolioManager error if the caller does not have the MINTER_ROLE.
   */
  modifier onlyMinter() {
    if (!_checkRole(MINTER_ROLE, msg.sender)) {
      revert ErrorLibrary.CallerNotPortfolioManager();
    }
    _;
  }

  /**
   * @dev Initializes the contract by setting the access controller address.
   * @param _accessController Address of the AccessController contract responsible for role management.
   */
  function __AccessModifiers_init(
    address _accessController
  ) internal onlyInitializing {
    if (_accessController == address(0)) revert ErrorLibrary.InvalidAddress();
    accessController = IAccessController(_accessController);
  }

  /**
   * @notice Checks if a user has a specific role.
   * @param _role The role identifier to check.
   * @param _user The address of the user to check for the role.
   * @return A boolean indicating whether the user has the specified role.
   */
  function _checkRole(
    bytes32 _role,
    address _user
  ) private view returns (bool) {
    return accessController.hasRole(_role, _user);
  }
}

// contracts/core/interfaces/IPortfolio.sol

/**
 * @title Portfolio for the Portfolio
 * @author Velvet.Capital
 * @notice This contract is used by the user to deposit and withdraw from the portfolio
 * @dev This contract includes functionalities:
 *      1. Deposit in the particular fund
 *      2. Withdraw from the fund
 */

interface IPortfolio {
  function vault() external view returns (address);

  function feeModule() external view returns (address);

  function protocolConfig() external view returns (address);

  function tokenExclusionManager() external view returns (address);

  function accessController() external view returns (address);

  function paused() external view returns (bool);

  function assetManagementConfig() external view returns (address);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function init(
    FunctionParameters.PortfolioInitData calldata initData
  ) external;

  /**
   * @dev Sets up the initial assets for the pool.
   * @param tokens Underlying tokens to initialize the pool with
   */
  function initToken(address[] calldata tokens) external;

  // For Minting Shares
  function mintShares(address _to, uint256 _amount) external;

  function pullFromVault(address _token, uint256 _amount, address _to) external;

  /**
     * @notice The function swaps BNB into the portfolio tokens after a user makes an deposit
     * @dev The output of the swap is converted into USD to get the actual amount after slippage to calculate 
            the portfolio token amount to mint
     * @dev (tokenBalance, vaultBalance) has to be calculated before swapping for the _mintShareAmount function 
            because during the swap the amount will change but the portfolio token balance is still the same 
            (before minting)
     */
  function multiTokenDeposit(
    uint256[] calldata depositAmounts,
    uint256 _minMintAmount,
    IAllowanceTransfer.PermitBatch calldata _permit,
    bytes calldata _signature
  ) external;

  /**
   * @notice Allows a specified depositor to deposit tokens into the fund through a multi-token deposit.
   *         The deposited tokens are added to the vault, and the user is minted portfolio tokens representing their share.
   * @param _depositFor The address of the user the deposit is being made for.
   * @param depositAmounts An array of amounts corresponding to each token the user wishes to deposit.
   * @param _minMintAmount The minimum amount of portfolio tokens the user expects to receive for their deposit, protecting against slippage.
   */
  function multiTokenDepositFor(
    address _depositFor,
    uint256[] calldata depositAmounts,
    uint256 _minMintAmount
  ) external;

  /**
     * @notice The function swaps the amount of portfolio tokens represented by the amount of portfolio token back to 
               BNB and returns it to the user and burns the amount of portfolio token being withdrawn
     * @param _portfolioTokenAmount The portfolio token amount the user wants to withdraw from the fund
     */
  function multiTokenWithdrawal(
    uint256 _portfolioTokenAmount,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external;

  /**
   * @notice Allows an approved user to withdraw portfolio tokens on behalf of another user.
   * @param _withdrawFor The address of the user for whom the withdrawal is being made.
   * @param _portfolioTokenAmount The amount of portfolio tokens to withdraw.
   */
  function multiTokenWithdrawalFor(
    address _withdrawFor,
    address _tokenReceiver,
    uint256 _portfolioTokenAmount,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) external;

  /**
    @notice The function returns lastRebalanced time
  */
  function getLastRebalance() external view returns (uint256);

  /**
    @notice The function returns lastPaused time
  */
  function getLastPaused() external view returns (uint256);

  function getTokens() external view returns (address[] memory);

  function updateTokenList(address[] memory tokens) external;

  function userLastDepositTime(address owner) external view returns (uint256);

  function _checkCoolDownPeriod(address _user) external view;

  function getTokenBalancesOf(
    address[] memory,
    address
  ) external view returns (uint256[] memory);

  function getVaultValueInUSD(
    IPriceOracle,
    address[] memory,
    uint256,
    address
  ) external view returns (uint256);

  function _calculateMintAmount(uint256, uint256) external returns (uint256);

  function vaultInteraction(
    address _target,
    bytes memory _claimCalldata
  ) external;
}

// contracts/core/calculations/VaultCalculations.sol

/**
 * @title VaultCalculations
 * @dev Extends the Dependencies and TokenCalculations contracts to provide additional calculation functionalities for vault operations.
 * Includes functions for determining mint amounts based on deposits, calculating token balances, and evaluating vault value in USD.
 */
abstract contract VaultCalculations is Dependencies, TokenCalculations {
  /**
   * @notice Calculates the amount of portfolio tokens to mint based on the deposit ratio and the total supply of portfolio tokens.
   * @param _depositRatio The ratio of the user's deposit to the total value of the vault.
   * @param _totalSupply The current total supply of portfolio tokens.
   * @return The amount of portfolio tokens to mint for the given deposit.
   */
  function _getTokenAmountToMint(
    uint256 _depositRatio,
    uint256 _totalSupply,
    IAssetManagementConfig _assetManagementConfig
  ) internal view returns (uint256) {
    uint256 mintAmount = _calculateMintAmount(_depositRatio, _totalSupply);
    if (mintAmount < _assetManagementConfig.minPortfolioTokenHoldingAmount()) {
      revert ErrorLibrary.MintedAmountIsNotAccepted();
    }
    return mintAmount;
  }

  /**
   * @notice Calculates the total USD value of the vault by converting the balance of each token in the vault to USD.
   * @param _oracle The address of the price oracle contract.
   * @param _tokens The list of token addresses in the vault.
   * @param _totalSupply The current total supply of the vault's portfolio token.
   * @param _vault The address of the vault.
   * @return vaultValue The total USD value of the vault.
   */
  function getVaultValueInUSD(
    IPriceOracle _oracle,
    address[] memory _tokens,
    uint256 _totalSupply,
    address _vault
  ) external view returns (uint256 vaultValue) {
    if (_totalSupply == 0) return 0;

    uint256 _tokenBalanceInUSD;
    uint256 tokensLength = _tokens.length;
    for (uint256 i; i < tokensLength; i++) {
      address _token = _tokens[i];
      if (!protocolConfig().isTokenEnabled(_token))
        revert ErrorLibrary.TokenNotEnabled();
      _tokenBalanceInUSD = _oracle.convertToUSD18Decimals(
        _token,
        IERC20Upgradeable_1(_token).balanceOf(_vault)
      );

      vaultValue += _tokenBalanceInUSD;
    }
  }
}

// contracts/core/checks/ChecksAndValidations.sol

/**
 * @title ChecksAndValidations
 * @dev Provides a suite of functions for performing various checks and validations across the platform, ensuring consistency and security in operations.
 * This abstract contract relies on inherited configurations from Dependencies to access global settings and state.
 */
abstract contract ChecksAndValidations is Dependencies {
  /**
   * @notice Validates the mint amount against a user-specified minimum to protect against slippage.
   * @param _mintAmount The amount of tokens calculated to be minted based on the user's deposited assets.
   * @param _minMintAmount The minimum acceptable amount of tokens the user expects to receive, preventing excessive slippage.
   */
  function _verifyUserMintedAmount(
    uint256 _mintAmount,
    uint256 _minMintAmount
  ) internal pure {
    if (_minMintAmount > _mintAmount) revert ErrorLibrary.InvalidMintAmount();
  }

  /**
   * @notice Verifies conditions before allowing an deposit to proceed.
   * @param _user The address of the user attempting to make the deposit.
   * @param _tokensLength The number of tokens in the portfolio at the time of deposit.
   * Ensures that the user is allowed to deposit based on the portfolio's public status and their whitelisting status.
   * Checks that the protocol is not paused and that the portfolio is properly initialized with tokens.
   */
  function _beforeDepositCheck(address _user, uint256 _tokensLength) internal {
    IAssetManagementConfig assetManagementConfig = assetManagementConfig();
    IProtocolConfig protocolConfig = protocolConfig();
    if (
      !(assetManagementConfig.publicPortfolio() ||
        assetManagementConfig.whitelistedUsers(_user)) ||
      _user == assetManagementConfig.assetManagerTreasury() ||
      _user == protocolConfig.velvetTreasury()
    ) {
      revert ErrorLibrary.UserNotAllowedToDeposit();
    }
    if (protocolConfig.isProtocolPaused()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (_tokensLength == 0) {
      revert ErrorLibrary.PortfolioTokenNotInitialized();
    }
  }

  /**
   * @notice Performs checks before allowing a withdrawal operation to proceed.
   * @param owner The address of the token owner initiating the withdrawal.
   * @param portfolio The portfolio contract from which tokens are being withdrawn.
   * @param _tokenAmount The amount of portfolio tokens the user wishes to withdraw.
   * Verifies that the protocol is not in an emergency pause state.
   * Confirms that the user has sufficient tokens for the withdrawal.
   * Ensures that the withdrawal does not result in a balance below the minimum allowed portfolio token amount.
   */
  function _beforeWithdrawCheck(
    address owner,
    IPortfolio portfolio,
    uint256 _tokenAmount,
    uint256 _tokensLength,
    address[] memory _exemptionTokens
  ) internal view {
    IProtocolConfig protocolConfig = protocolConfig();
    if (protocolConfig.isProtocolEmergencyPaused()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    uint256 balanceOfUser = portfolio.balanceOf(owner);
    if (_tokenAmount > balanceOfUser) {
      revert ErrorLibrary.CallerNotHavingGivenPortfolioTokenAmount();
    }
    uint256 balanceAfterRedemption = balanceOfUser - _tokenAmount;
    if (
      balanceAfterRedemption != 0 &&
      balanceAfterRedemption < protocolConfig.minPortfolioTokenHoldingAmount()
    ) {
      revert ErrorLibrary.CallerNeedToMaintainMinTokenAmount();
    }
    if (_exemptionTokens.length > _tokensLength) {
      revert ErrorLibrary.InvalidExemptionTokensLength();
    }
  }

  /**
   * @notice Validates a token before initializing it in the portfolio.
   * @param token The address of the token being validated.
   * Checks that the token is whitelisted if token whitelisting is enabled in the asset management configuration.
   * Ensures that the token address is not the zero address.
   */
  function _beforeInitCheck(address token) internal {
    IAssetManagementConfig assetManagementConfig = assetManagementConfig();
    if (
      (assetManagementConfig.tokenWhitelistingEnabled() &&
        !assetManagementConfig.isTokenWhitelisted(token))
    ) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
    if (token == address(0)) {
      revert ErrorLibrary.InvalidTokenAddress();
    }
  }
}

// contracts/core/config/VaultConfig.sol

// Importing AccessModifiers for role-based access control.

// Importing ChecksAndValidations for performing various checks and validations across the system.

// Importing ErrorLibrary for custom error messages.

/**
 * @title VaultConfig
 * @dev Inherits AccessModifiers and ChecksAndValidations to manage vault configurations.
 * Handles initialization and updating of _tokens within the vault. Maintains a list of _tokens
 * associated with the vault and provides mechanisms to update these _tokens securely.
 */
abstract contract VaultConfig is AccessModifiers, ChecksAndValidations {
  // Array storing addresses of underlying _tokens in the vault.
  address[] internal tokens;

  // Addresses of the vault and associated safe module.
  address public vault;
  address public safeModule;

  // Mapping to track tokens provided by asset managers during updates.
  mapping(address => bool) internal _previousToken;

  // Event emitted when public swap/trade is enabled for the vault.
  event PublicSwapEnabled(address indexed portfolio);

  // Events for logging deposit and withdrawal operations.
  event Deposited(
    address indexed portfolio,
    address indexed user,
    uint256 indexed mintedAmount,
    uint256 userBalanceAfterDeposit
  );
  event Withdrawn(
    address indexed user,
    uint256 indexed burnedAmount,
    address indexed portfolio,
    address[] portfolioTokens,
    uint256 userBalanceAfterWithdrawal,
    uint256[] userWithdrawalAmounts
  );
  event UserDepositedAmounts(
    uint256[] depositedAmounts,
    address[] portfolioTokens
  );

  // Initializes the vault with addresses of the vault and safe module.
  function __VaultConfig_init(
    address _vault,
    address _safeModule
  ) internal onlyInitializing {
    if (_vault == address(0) || _safeModule == address(0))
      revert ErrorLibrary.InvalidAddress();
    vault = _vault;
    safeModule = _safeModule;
  }

  /**
   * @dev Initializes the vault with a set of _tokens.
   * @param _tokens Array of token addresses to initialize the vault.
   * Only callable by the super admin. Checks for the maximum asset limit and prevents re-initialization.
   */
  function initToken(address[] calldata _tokens) external onlySuperAdmin {
    uint256 _assetLimit = protocolConfig().assetLimit();
    uint256 tokensLength = _tokens.length;
    if (tokensLength > _assetLimit)
      revert ErrorLibrary.TokenCountOutOfLimit(_assetLimit);
    if (tokens.length != 0) {
      revert ErrorLibrary.AlreadyInitialized();
    }
    for (uint256 i; i < tokensLength; i++) {
      address _token = _tokens[i];
      _checkToken(_token);
      tokens.push(_token);
    }
    _resetPreviousTokenList(_tokens);
    emit PublicSwapEnabled(address(this));
  }

  /**
   * @dev Updates the token list of the vault.
   * Can only be called by the rebalancer contract. Checks for the maximum asset limit.
   * @param _tokens New array of token addresses for the vault.
   */
  function updateTokenList(
    address[] calldata _tokens
  ) external onlyRebalancerContract {
    uint256 _assetLimit = protocolConfig().assetLimit();
    uint256 tokenLength = _tokens.length;

    if (tokenLength > _assetLimit)
      revert ErrorLibrary.TokenCountOutOfLimit(_assetLimit);

    for (uint256 i; i < tokenLength; i++) {
      _checkToken(_tokens[i]);
    }
    _resetPreviousTokenList(_tokens);
    tokens = _tokens;
  }

  /**
   * @notice Validates a token for inclusion in the vault
   * @dev Performs initial checks and ensures the token is not already in the vault
   * @param _token The address of the token to be validated and registered.
   */
  function _checkToken(address _token) internal {
      _beforeInitCheck(_token);
      if (_previousToken[_token]) {
        revert ErrorLibrary.TokenAlreadyExist();
      }
      _previousToken[_token] = true;
  }

  /**
    @dev Resets token state to false for reuse by asset manager.
    @param _tokens Array of _tokens to reset.
  */
  function _resetPreviousTokenList(address[] calldata _tokens) internal {
    uint256 tokensLength = _tokens.length;
    for (uint256 i; i < tokensLength; i++) {
      delete _previousToken[_tokens[i]];
    }
  }

  /**
    @dev Returns the current list of _tokens in the vault.
    @return Array of token addresses.
  */
  function getTokens() external view returns (address[] memory) {
    return tokens;
  }

  // Reserved storage gap to accommodate potential future layout adjustments.
  uint256[49] private __uint256GapVaultConfig;
}

// contracts/core/token/PortfolioToken.sol

/**
 * @title PortfolioToken
 * @notice Represents a tokenized share of the portfolio fund, facilitating deposit and withdrawal by minting and burning portfolio tokens.
 * @dev Inherits from ERC20Upgradeable for standard token functionality, and utilizes various contracts for managing access controls,
 * cooldown periods, dependency configurations, and user-related functionalities.
 */
abstract contract PortfolioToken is
  ERC20Upgradeable,
  AccessModifiers,
  CooldownManager,
  Dependencies,
  UserManagement
{
  // Initializes the contract with a name and symbol for the ERC20 token.
  function __PortfolioToken_init(
    string calldata _name,
    string calldata _symbol
  ) internal onlyInitializing {
    __ERC20_init(_name, _symbol);
  }

  /**
   * @notice Mints portfolio tokens to a specified address.
   * @dev Only callable by an address with the minter role. This function increases the recipient's balance by the specified amount.
   * @param _to The recipient address.
   * @param _amount The amount of tokens to mint.
   */
  function mintShares(address _to, uint256 _amount) external onlyMinter {
    _mint(_to, _amount);
  }

  /**
   * @notice Checks if the fee value is greater than zero and the recipient is not one of the special treasury addresses.
   * @dev Used internally to validate fee transactions.
   * @param _fee The fee amount being checked.
   * @param _to The recipient of the fee.
   * @return bool Returns true if the conditions are met, false otherwise.
   */
  function _mintAndBurnCheck(
    uint256 _fee,
    address _to,
    IAssetManagementConfig _assetManagementConfig
  ) internal returns (bool) {
    return (_fee > 0 &&
      !(_to == _assetManagementConfig.assetManagerTreasury() ||
        _to == protocolConfig().velvetTreasury()));
  }

  /**
   * @notice Mints new portfolio tokens, considering the entry fee, if applicable, and assigns them to the specified address.
   * @param _to Address to which the minted tokens will be assigned.
   * @param _mintAmount Amount of portfolio tokens to mint.
   * @return The amount of tokens minted after deducting any entry fee.
   */
  function _mintTokenAndSetCooldown(
    address _to,
    uint256 _mintAmount,
    IAssetManagementConfig _assetManagementConfig
  ) internal returns (uint256) {
    uint256 entryFee = _assetManagementConfig.entryFee();

    if (_mintAndBurnCheck(entryFee, _to, _assetManagementConfig)) {
      _mintAmount = feeModule()._chargeEntryOrExitFee(_mintAmount, entryFee);
    }

    _mint(_to, _mintAmount);

    // Updates the cooldown period based on the minting action.
    userCooldownPeriod[_to] = _calculateCooldownPeriod(
      balanceOf(_to),
      _mintAmount,
      protocolConfig().cooldownPeriod(),
      userCooldownPeriod[_to],
      userLastDepositTime[_to]
    );
    userLastDepositTime[_to] = block.timestamp;

    return _mintAmount;
  }

  /**
   * @notice Burns a specified amount of portfolio tokens from an address, considering the exit fee, if applicable.
   * @param _to Address from which the tokens will be burned.
   * @param _mintAmount Amount of portfolio tokens to burn.
   * @return afterFeeAmount The amount of tokens burned after deducting any exit fee.
   */
  function _burnWithdraw(
    address _to,
    uint256 _mintAmount
  ) internal returns (uint256 afterFeeAmount) {
    IAssetManagementConfig _assetManagementConfig = assetManagementConfig();
    uint256 exitFee = _assetManagementConfig.exitFee();

    afterFeeAmount = _mintAmount;
    if (_mintAndBurnCheck(exitFee, _to, _assetManagementConfig)) {
      afterFeeAmount = feeModule()._chargeEntryOrExitFee(_mintAmount, exitFee);
    }

    _burn(_to, _mintAmount);
  }

  /**
   * @notice Enforces checks before token transfers, such as transfer restrictions and cooldown periods.
   * @param from Address sending the tokens.
   * @param to Address receiving the tokens.
   * @param amount Amount of tokens being transferred.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    IAssetManagementConfig assetManagementConfig = assetManagementConfig();
    super._beforeTokenTransfer(from, to, amount);
    if (from == address(0) || to == address(0)) {
      return;
    }
    if (
      !(assetManagementConfig.transferableToPublic() ||
        (assetManagementConfig.transferable() &&
          assetManagementConfig.whitelistedUsers(to)))
    ) {
      revert ErrorLibrary.Transferprohibited();
    }
    _checkCoolDownPeriod(from);
  }

  /**
   * @notice Updates user records after token transfers to ensure accurate tracking of user balances (for token removal - UserManagement).
   * @param _from Address of the sender in the transfer.
   * @param _to Address of the recipient in the transfer.
   * @param _amount Amount of tokens transferred.
   */
  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    super._afterTokenTransfer(_from, _to, _amount);
    if (_from == address(0)) {
      _updateUserRecord(_to, balanceOf(_to));
    } else if (_to == address(0)) {
      _updateUserRecord(_from, balanceOf(_from));
    } else {
      _updateUserRecord(_from, balanceOf(_from));
      _updateUserRecord(_to, balanceOf(_to));
    }
  }
}

// contracts/core/management/VaultManager.sol

/**
 * @title VaultManager
 * @dev Extends functionality for managing deposits and withdrawals in the vault.
 * Combines configurations, calculations, fee handling, and token operations.
 */
abstract contract VaultManager is
  VaultConfig,
  VaultCalculations,
  FeeManager,
  PortfolioToken,
  ReentrancyGuardUpgradeable
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
   * @param borrowManager The address of borrowManager contract
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
    // Prepare the data for ERC20 token transfer
    bytes memory inputData = abi.encodeWithSelector(
      IERC20Upgradeable_1.transfer.selector,
      _to,
      _amount
    );

    // Execute the transfer through the safe module and check for success
    (, bytes memory data) = IVelvetSafeModule(safeModule).executeWallet(
      _token,
      inputData
    );

    // Ensure the transfer was successful; revert if not
    if (!(data.length == 0 || abi.decode(data, (bool)))) {
      revert ErrorLibrary.TransferFailed();
    }
  }

  /**
   * @dev Claims rewards for a target address by executing a transfer through the safe module.
   * Only the rebalancer contract is allowed to call this function.
   * @param _target The address where the rewards are claimed from
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
    // Execute the transfer through the safe module and check for success
    (bool success, ) = IVelvetSafeModule(safeModule).executeWallet(
      _target,
      _claimCalldata
    );

    if (!success) revert ErrorLibrary.CallFailed();
  }

  /**
   * @notice Internal function to handle the multi-token deposit logic.
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

    // Verify that the user is allowed to deposit and that the system is not paused.
    _beforeDepositCheck(_depositFor, tokens.length);
    // Charge any applicable fees.
    _chargeFees(_depositFor);

    // Process the multi-token deposit, adjusting for vault token ratios.
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
    // Verify that the user is allowed to deposit and that the system is not paused.
    _beforeDepositCheck(_depositFor, tokens.length);
    // Charge any applicable fees.
    _chargeFees(_depositFor);

    // Process the multi-token deposit, adjusting for vault token ratios.
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

    IAssetManagementConfig _assetManagementConfig = assetManagementConfig();
    // If the total supply is zero, this is the first deposit, and tokens are minted based on the initial amount.
    if (_totalSupply == 0) {
      tokenAmount = _assetManagementConfig.initialPortfolioAmount();
      // Reset the high watermark to zero if it's not the first deposit.
      feeModule().resetHighWaterMark();
    } else {
      // Calculate the amount of portfolio tokens to mint based on the deposit.
      tokenAmount = _getTokenAmountToMint(
        _depositRatio,
        _totalSupply,
        _assetManagementConfig
      );
    }

    // Mint the calculated portfolio tokens to the user, applying any cooldown periods.
    tokenAmount = _mintTokenAndSetCooldown(
      _depositFor,
      tokenAmount,
      _assetManagementConfig
    );

    // Ensure the minted amount meets the user's minimum expectation to mitigate slippage.
    _verifyUserMintedAmount(tokenAmount, _minMintAmount);

    // Notify listeners of the deposit event.
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
   * @param _tokenReceiver The address to receive the withdrawn tokens.
   * @param _portfolioTokenAmount The amount of portfolio tokens to burn for withdrawal.
   * @param _exemptionTokens The array of tokens that are exempt from withdrawal if transfer fails.
   * @param repayData Struct containing data for repaying borrows.
   */
  function _multiTokenWithdrawal(
    address _withdrawFor,
    address _tokenReceiver,
    uint256 _portfolioTokenAmount,
    address[] memory _exemptionTokens,
    FunctionParameters.withdrawRepayParams calldata repayData
  ) internal virtual {
    // Retrieve the list of tokens currently in the portfolio.
    address[] memory portfolioTokens = tokens;
    uint256 portfolioTokenLength = portfolioTokens.length;

    // Perform pre-withdrawal checks, including balance and cooldown verification.
    _performWithdrawalChecks(
      _withdrawFor,
      _portfolioTokenAmount,
      portfolioTokenLength,
      _exemptionTokens
    );

    // Calculate the total supply of portfolio tokens for proportion calculations.
    uint256 totalSupplyPortfolio = totalSupply();
    // Burn the user's portfolio tokens and calculate the adjusted withdrawal amount post-fees.
    _portfolioTokenAmount = _burnWithdraw(_withdrawFor, _portfolioTokenAmount);

    // Repay any outstanding borrows
    _borrowManager.repayBorrow(
      _portfolioTokenAmount,
      totalSupplyPortfolio,
      repayData
    );

    // Process the withdrawal for each token and get the withdrawal amounts
    uint256[] memory userWithdrawalAmounts = _processTokenWithdrawals(
      _tokenReceiver,
      _portfolioTokenAmount,
      totalSupplyPortfolio,
      portfolioTokens,
      _exemptionTokens
    );

    // Notify listeners of the withdrawal event.
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
   * @notice Performs all necessary checks before withdrawal.
   * @param _withdrawFor The address of the user making the withdrawal.
   * @param _portfolioTokenAmount The amount of portfolio tokens to withdraw.
   * @param portfolioTokenLength The number of tokens in the portfolio.
   * @param _exemptionTokens The array of tokens that are exempt from withdrawal if transfer fails.
   */
  function _performWithdrawalChecks(
    address _withdrawFor,
    uint256 _portfolioTokenAmount,
    uint256 portfolioTokenLength,
    address[] memory _exemptionTokens
  ) private {
    // Perform pre-withdrawal checks, including balance and cooldown verification.
    _beforeWithdrawCheck(
      _withdrawFor,
      IPortfolio(address(this)),
      _portfolioTokenAmount,
      portfolioTokenLength,
      _exemptionTokens
    );
    // Validate the cooldown period of the user.
    _checkCoolDownPeriod(_withdrawFor);
    // Charge any applicable fees before withdrawal.
    _chargeFees(_withdrawFor);
  }

  /**
   * @notice Processes the withdrawal for all tokens in the portfolio.
   * @param _tokenReceiver The address to receive the withdrawn tokens.
   * @param _portfolioTokenAmount The amount of portfolio tokens being withdrawn.
   * @param totalSupplyPortfolio The total supply of portfolio tokens.
   * @param portfolioTokens The array of token addresses in the portfolio.
   * @param _exemptionTokens The array of tokens that are exempt from withdrawal if transfer fails.
   * @return An array of withdrawal amounts for each token.
   */
  function _processTokenWithdrawals(
    address _tokenReceiver,
    uint256 _portfolioTokenAmount,
    uint256 totalSupplyPortfolio,
    address[] memory portfolioTokens,
    address[] memory _exemptionTokens
  ) private returns (uint256[] memory) {
    uint256 portfolioTokenLength = portfolioTokens.length;
    uint256[] memory userWithdrawalAmounts = new uint256[](
      portfolioTokenLength
    );
    uint256 exemptionIndex = 0;

    // Get controllers data for the vault
    TokenBalanceLibrary.ControllerData[]
      memory controllersData = TokenBalanceLibrary.getControllersData(
        vault,
        _protocolConfig
      );

    for (uint256 i; i < portfolioTokenLength; i++) {
      (userWithdrawalAmounts[i], exemptionIndex) = _processTokenWithdrawal(
        portfolioTokens[i],
        _tokenReceiver,
        _portfolioTokenAmount,
        totalSupplyPortfolio,
        _exemptionTokens,
        exemptionIndex,
        controllersData
      );
    }

    return userWithdrawalAmounts;
  }

  /**
   * @notice Processes the withdrawal for a single token.
   * @param _token The address of the token to withdraw.
   * @param _tokenReceiver The address to receive the withdrawn tokens.
   * @param _portfolioTokenAmount The amount of portfolio tokens being withdrawn.
   * @param totalSupplyPortfolio The total supply of portfolio tokens.
   * @param _exemptionTokens The array of tokens that are exempt from withdrawal if transfer fails.
   * @param exemptionIndex The current index in the exemption tokens array.
   * @param controllersData The array of controller data for balance calculations.
   * @return The amount of tokens withdrawn and the updated exemption index.
   */
  function _processTokenWithdrawal(
    address _token,
    address _tokenReceiver,
    uint256 _portfolioTokenAmount,
    uint256 totalSupplyPortfolio,
    address[] memory _exemptionTokens,
    uint256 exemptionIndex,
    TokenBalanceLibrary.ControllerData[] memory controllersData
  ) private returns (uint256, uint256) {
    // Calculate the proportion of each token to return based on the burned portfolio tokens.
    uint256 tokenBalance = TokenBalanceLibrary._getAdjustedTokenBalance(
      _token,
      vault,
      _protocolConfig,
      controllersData
    );
    tokenBalance =
      (tokenBalance * _portfolioTokenAmount) /
      totalSupplyPortfolio;

    // Prepare the data for ERC20 token transfer
    bytes memory inputData = abi.encodeWithSelector(
      IERC20Upgradeable_1.transfer.selector,
      _tokenReceiver,
      tokenBalance
    );

    // Execute the transfer through the safe module and check for success
    try IVelvetSafeModule(safeModule).executeWallet(_token, inputData) {
      // Check if the token balance is zero and the current token is not an exemption token, revert with an error.
      // This check is necessary because if there is any rebase token or the protocol sets the balance to zero,
      // we need to be able to withdraw other tokens. The balance for a withdrawal should always be >0,
      // except when the user accepts to lose this token.
      if (tokenBalance == 0) {
        if (_exemptionTokens[exemptionIndex] == _token) exemptionIndex += 1;
        else revert ErrorLibrary.WithdrawalAmountIsSmall();
      }
      return (tokenBalance, exemptionIndex);
    } catch {
      // Checking if exception token was mentioned in exceptionToken array
      if (_exemptionTokens[exemptionIndex] != _token) {
        revert ErrorLibrary.InvalidExemptionTokens();
      }
      return (0, exemptionIndex + 1);
    }
  }

  /**
   * @notice Transfers tokens from the user to the vault using permit2 transferfrom.
   * @dev Utilizes `TransferHelper` for secure token transfer from user to vault.
   * @param _token Address of the token to be transferred.
   * @param _depositAmount Amount of the token to be transferred.
   * @param _from The address from which the tokens are transferred.
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
   * @param _depositFor The address that will receive the portfolio tokens when investing on their behalf.
   * @return The minimum deposit ratio after deposits.
   */
  function _multiTokenTransferWithPermit(
    uint256[] calldata depositAmounts,
    IAllowanceTransfer.PermitBatch calldata _permit,
    bytes calldata _signature,
    address _depositFor
  ) internal returns (uint256) {
    // Validate deposit amounts and get initial token balances
    (
      uint256 amountLength,
      address[] memory portfolioTokens,
      uint256[] memory tokenBalancesBefore,
      TokenBalanceLibrary.ControllerData[] memory controllersData
    ) = _validateAndGetBalances(depositAmounts);

    try permit2.permit(msg.sender, _permit, _signature) {
      // No further implementation needed if permit succeeds
    } catch {
      // Check allowance for each token in depositAmounts array
      uint256 depositAmountsLength = depositAmounts.length;
      for (uint256 i; i < depositAmountsLength; i++) {
        if (
          IERC20Upgradeable_1(portfolioTokens[i]).allowance(
            msg.sender,
            address(this)
          ) < depositAmounts[i]
        ) revert ErrorLibrary.InsufficientAllowance();
      }
    }

    // Handles the token transfer and minRatio calculations
    return
      _handleTokenTransfer(
        _depositFor,
        amountLength,
        depositAmounts,
        portfolioTokens,
        tokenBalancesBefore,
        true,
        controllersData
      );
  }

  /**
   * @notice Processes multi-token deposits by calculating the minimum deposit ratio.
   * @dev Ensures that the deposited token amounts align with the current vault token ratios.
   * @param _from The address from which the tokens are transferred.
   * @param depositAmounts Array of amounts for each token the user wants to deposit.
   * @return The minimum deposit ratio after deposits.
   */
  function _multiTokenTransfer(
    address _from,
    uint256[] calldata depositAmounts
  ) internal returns (uint256) {
    // Validate deposit amounts and get initial token balances
    (
      uint256 amountLength,
      address[] memory portfolioTokens,
      uint256[] memory tokenBalancesBefore,
      TokenBalanceLibrary.ControllerData[] memory controllersData
    ) = _validateAndGetBalances(depositAmounts);

    // Handles the token transfer and minRatio calculations
    return
      _handleTokenTransfer(
        _from,
        amountLength,
        depositAmounts,
        portfolioTokens,
        tokenBalancesBefore,
        false,
        controllersData
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
  )
    internal
    view
    returns (
      uint256,
      address[] memory,
      uint256[] memory,
      TokenBalanceLibrary.ControllerData[] memory
    )
  {
    uint256 amountLength = depositAmounts.length;
    address[] memory portfolioTokens = tokens;

    // Validate the deposit amounts match the number of tokens in the vault
    if (amountLength != portfolioTokens.length) {
      revert ErrorLibrary.InvalidDepositInputLength();
    }

    // Get current token balances in the vault for ratio calculations
    (
      uint256[] memory tokenBalancesBefore,
      TokenBalanceLibrary.ControllerData[] memory controllersData
    ) = TokenBalanceLibrary.getTokenBalancesOf(
        portfolioTokens,
        vault,
        _protocolConfig
      );

    return (
      amountLength,
      portfolioTokens,
      tokenBalancesBefore,
      controllersData
    );
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
    bool usePermit,
    TokenBalanceLibrary.ControllerData[] memory controllersData
  ) internal returns (uint256) {
    if (totalSupply() == 0) {
      return
        _handleEmptyVaultTransfer(
          _from,
          amountLength,
          depositAmounts,
          portfolioTokens,
          tokenBalancesBefore,
          usePermit
        );
    }

    uint256 _minRatio = _calculateMinRatio(
      amountLength,
      depositAmounts,
      tokenBalancesBefore
    );
    return
      _executeTransfers(
        _from,
        amountLength,
        portfolioTokens,
        tokenBalancesBefore,
        _minRatio,
        usePermit,
        controllersData
      );
  }

  /**
   * @notice Handles token transfers for an empty vault.
   * @dev This function is called when the total supply is zero, indicating an empty vault.
   * It transfers the specified amounts of each token from the user to the vault.
   * @param _from The address from which tokens are transferred.
   * @param amountLength The number of tokens to be transferred.
   * @param depositAmounts An array of amounts to be deposited for each token.
   * @param portfolioTokens An array of token addresses in the portfolio.
   * @param tokenBalancesBefore An array of token balances before the transfer.
   * @param usePermit A boolean indicating whether to use permit for transfers.
   * @return uint256 Returns 0 as there's no ratio to calculate for an empty vault.
   */
  function _handleEmptyVaultTransfer(
    address _from,
    uint256 amountLength,
    uint256[] calldata depositAmounts,
    address[] memory portfolioTokens,
    uint256[] memory tokenBalancesBefore,
    bool usePermit
  ) private returns (uint256) {
    uint256[] memory depositedAmounts = new uint256[](amountLength);

    for (uint256 i; i < amountLength; i++) {
      uint256 depositAmount = depositAmounts[i];
      if (depositAmount == 0) revert ErrorLibrary.AmountCannotBeZero();
      address token = portfolioTokens[i];
      _transferToken(_from, token, depositAmount, usePermit);

      if (
        TokenBalanceLibrary._getTokenBalanceOf(token, vault) <=
        tokenBalancesBefore[i]
      ) {
        revert ErrorLibrary.TransferFailed();
      }
      depositedAmounts[i] = depositAmount;
    }

    emit UserDepositedAmounts(depositedAmounts, portfolioTokens);
    return 0;
  }

  /**
   * @notice Calculates the minimum ratio among all deposit amounts and their corresponding vault balances.
   * @dev This function iterates through all tokens and calculates the ratio of deposit amount to vault balance,
   * then returns the minimum ratio found.
   * @param amountLength The number of tokens to process.
   * @param depositAmounts An array of deposit amounts for each token.
   * @param tokenBalancesBefore An array of token balances in the vault before the deposit.
   * @return uint256 The minimum ratio found among all tokens.
   */
  function _calculateMinRatio(
    uint256 amountLength,
    uint256[] calldata depositAmounts,
    uint256[] memory tokenBalancesBefore
  ) private pure returns (uint256) {
    uint256 _minRatio = type(uint256).max;
    for (uint256 i = 0; i < amountLength; i++) {
      uint256 _currentRatio = _getDepositToVaultBalanceRatio(
        depositAmounts[i],
        tokenBalancesBefore[i]
      );
      _minRatio = MathUtils._min(_currentRatio, _minRatio);
    }
    return _minRatio;
  }

  /**
   * @notice Executes token transfers from the user to the vault based on the calculated minimum ratio.
   * @dev This function transfers tokens, updates balances, and calculates the new minimum ratio after transfers.
   * @param _from The address from which tokens are transferred.
   * @param amountLength The number of tokens to process.
   * @param portfolioTokens An array of token addresses in the portfolio.
   * @param tokenBalancesBefore An array of token balances before the transfer.
   * @param _minRatio The minimum ratio calculated before transfers.
   * @param usePermit A boolean indicating whether to use permit for transfers.
   * @param controllersData An array of controller data for balance calculations.
   * @return uint256 The new minimum ratio after all transfers are completed.
   */
  function _executeTransfers(
    address _from,
    uint256 amountLength,
    address[] memory portfolioTokens,
    uint256[] memory tokenBalancesBefore,
    uint256 _minRatio,
    bool usePermit,
    TokenBalanceLibrary.ControllerData[] memory controllersData
  ) private returns (uint256) {
    uint256[] memory depositedAmounts = new uint256[](amountLength);
    uint256 _minRatioAfterTransfer = type(uint256).max;

    for (uint256 i; i < amountLength; i++) {
      address token = portfolioTokens[i];
      uint256 tokenBalanceBefore = tokenBalancesBefore[i];
      uint256 transferAmount = (_minRatio * tokenBalanceBefore) /
        ONE_ETH_IN_WEI;
      depositedAmounts[i] = transferAmount;

      _transferToken(_from, token, transferAmount, usePermit);

      uint256 tokenBalanceAfter = TokenBalanceLibrary._getAdjustedTokenBalance(
        token,
        vault,
        _protocolConfig,
        controllersData
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

  /**
   * @notice Transfers a specified amount of tokens from a user to the vault.
   * @dev This function chooses between permit and regular transfer based on the usePermit parameter.
   * @param _from The address from which tokens are transferred.
   * @param token The address of the token to transfer.
   * @param amount The amount of tokens to transfer.
   * @param usePermit A boolean indicating whether to use permit for the transfer.
   */
  function _transferToken(
    address _from,
    address token,
    uint256 amount,
    bool usePermit
  ) private {
    if (usePermit) {
      _transferToVaultWithPermit(_from, token, amount);
    } else {
      _transferToVault(_from, token, amount);
    }
  }
}

// contracts/core/Portfolio.sol

/**
 * @title Portfolio
 * @author Velvet.Capital
 * @notice Serves as the primary interface for users to interact with the portfolio, allowing deposits and withdrawals.
 * @dev Integrates with multiple modules to provide a comprehensive solution for portfolio fund management, including asset management,
 *      protocol configuration, and fee handling. Supports upgradeability through UUPS pattern.
 */

contract Portfolio is OwnableUpgradeable, UUPSUpgradeable, VaultManager {
  // Configuration contracts for asset management, protocol parameters, and fee calculations.
  IAssetManagementConfig private _assetManagementConfig;
  IFeeModule private _feeModule;

  // Prevents the constructor from being called on the implementation contract, ensuring only proxy initialization is valid.
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializes the portfolio contract with necessary configurations.
   * @param initData Struct containing all necessary initialization parameters including asset management, protocol config, and fee module addresses.
   */
  function init(
    FunctionParameters.PortfolioInitData calldata initData
  ) external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    // Initializes configurations for vault management, token settings, access controls, and user management.
    __VaultConfig_init(initData._vault, initData._module);
    __PortfolioToken_init(initData._name, initData._symbol);
    __VaultManager_init(initData._protocolConfig, initData._borrowManager);
    __AccessModifiers_init(initData._accessController);
    __UserManagement_init(initData._tokenExclusionManager);

    // Sets up the contracts for managing assets, protocol parameters, and fee calculations.
    _assetManagementConfig = IAssetManagementConfig(
      initData._assetManagementConfig
    );
    _feeModule = IFeeModule(initData._feeModule);
  }

  // Provides a way to retrieve the asset management configuration.
  function assetManagementConfig()
    public
    view
    override(Dependencies)
    returns (IAssetManagementConfig)
  {
    return _assetManagementConfig;
  }

  // Provides a way to retrieve the protocol configuration.
  function protocolConfig()
    public
    view
    override(Dependencies)
    returns (IProtocolConfig)
  {
    return _protocolConfig;
  }

  // Provides a way to retrieve the fee module.
  function feeModule() public view override(Dependencies) returns (IFeeModule) {
    return _feeModule;
  }

  /**
   * @notice Authorizes the smart contract upgrade to a new implementation.
   * @dev Ensures that only the contract owner can perform the upgrade.
   * @param newImplementation The address of the new contract implementation.
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {
    // Intentionally left empty as required by an abstract contract
  }
}

