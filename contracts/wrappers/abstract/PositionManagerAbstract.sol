// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable-4.9.6/security/ReentrancyGuardUpgradeable.sol";
import { TransferHelper } from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import { INonfungiblePositionManager } from "./INonfungiblePositionManager.sol";
import { TokenCalculations } from "../../core/calculations/TokenCalculations.sol";
import { ErrorLibrary } from "../../library/ErrorLibrary.sol";
import { IPositionWrapper } from "./IPositionWrapper.sol";
import { WrapperFunctionParameters } from "../WrapperFunctionParameters.sol";
import { MathUtils } from "../../core/calculations/MathUtils.sol";
import { IAssetManagementConfig } from "../../config/assetManagement/IAssetManagementConfig.sol";
import { IAccessController } from "../../access/IAccessController.sol";
import { AccessRoles } from "../../access/AccessRoles.sol";

/**
 * @title PositionManagerAbstract
 * @dev Abstract contract for managing Uniswap V3 positions and representing them as ERC20 tokens.
 * This contract allows managing liquidity in Uniswap V3 positions through a tokenized interface.
 */
abstract contract PositionManagerAbstract is
  TokenCalculations,
  ReentrancyGuardUpgradeable,
  AccessRoles
{
  /// @notice Minimum amount of fees in smallest token unit that must be collected before they can be reinvested.
  uint256 internal constant MIN_REINVESTMENT_AMOUNT = 1000000;

  /// @dev Reference to the Uniswap V3 Non-Fungible Position Manager for managing liquidity positions.
  INonfungiblePositionManager internal uniswapV3PositionManager;

  /// @notice List of addresses for all deployed position wrapper contracts.
  address[] public deployedPositionWrappers;

  /// @dev Contract for managing asset configurations, used to enforce rules and parameters for asset operations.
  IAssetManagementConfig assetManagementConfig;

  /// @dev Access control contract for managing permissions and roles within the ecosystem.
  IAccessController accessController;

  /// @notice Mapping to check if a given address is an officially deployed wrapper position.
  /// @dev Helps in validating whether interactions are with legitimate wrappers.
  mapping(address => bool) public isWrappedPosition;

  event NewPositionCreated(
    address positionWrapper,
    address token0,
    address token1
  );

  event PositionInitializedAndDeposited(address positionManager);

  event LiquidityIncreased(address user, uint256 liquidity);
  event LiquidityDecreased(address user, uint256 liquidity);

  event PriceRangeUpdated(
    address positionManager,
    int24 tickLower,
    int24 tickUpper
  );

  /**
   * @dev Ensures that only an asset manager can call a function.
   */
  modifier onlyAssetManager() {
    if (!accessController.hasRole(ASSET_MANAGER, msg.sender))
      revert ErrorLibrary.CallerNotAssetManager();
    _;
  }

  /**
   * @notice Initializes the contract with essential configuration addresses and settings.
   * @dev This function is called once to configure the contract with the necessary addresses for asset management,
   *      access control, and the base implementation for position wrappers. It sets the address for the Uniswap V3
   *      Nonfungible Position Manager to a constant defined at contract creation.
   *      This function should be called as an initializer, ensuring it can only be called once to set up the contract state.
   * @param _assetManagerConfig The address of the asset management configuration contract, which defines rules and parameters for managing assets.
   * @param _accessController The address of the access controller contract, which manages permissions and roles within the contract ecosystem.
   */
  function PositionManagerAbstract__init(
    address _nonFungiblePositionManagerAddress,
    address _assetManagerConfig,
    address _accessController
  ) internal {
    uniswapV3PositionManager = INonfungiblePositionManager(
      _nonFungiblePositionManagerAddress
    );
    assetManagementConfig = IAssetManagementConfig(_assetManagerConfig);
    accessController = IAccessController(_accessController);
  }

  /**
   * @notice Increases the liquidity of an existing Uniswap V3 position and mints corresponding wrapper tokens.
   * @dev This function facilitates the addition of liquidity to an existing Uniswap V3 position. It handles the transfer
   *      of tokens from the caller, approves the Uniswap V3 Non-Fungible Position Manager to use these tokens, increases
   *      liquidity, mints wrapper tokens proportionate to the added liquidity, and handles any excess tokens ("dust").
   * @param _params The parameters required to deposit liquidity and mint wrapper tokens.
   */
  function increaseLiquidity(
    WrapperFunctionParameters.WrapperDepositParams memory _params
  ) external nonReentrant {
    uint256 tokenId = _params._positionWrapper.tokenId();

    address token0 = _params._positionWrapper.token0();
    address token1 = _params._positionWrapper.token1();

    // Reinvest any collected fees back into the pool before adding new liquidity.
    _collectFeesAndReinvest(
      _params._positionWrapper,
      tokenId,
      token0,
      token1,
      _params._tokenIn,
      _params._tokenOut,
      _params._amountIn
    );

    // Track token balances before the operation to calculate dust later.
    uint256 balance0Before = IERC20Upgradeable(token0).balanceOf(address(this));
    uint256 balance1Before = IERC20Upgradeable(token1).balanceOf(address(this));

    // Transfer the desired liquidity tokens from the caller to this contract.
    _transferTokensFromSender(
      token0,
      token1,
      _params._amount0Desired,
      _params._amount1Desired
    );

    uint256 balance0After = IERC20Upgradeable(token0).balanceOf(address(this));
    uint256 balance1After = IERC20Upgradeable(token1).balanceOf(address(this));

    _params._amount0Desired = balance0After - balance0Before;
    _params._amount1Desired = balance1After - balance1Before;

    // Approve the Uniswap manager to use the tokens for liquidity.
    _approveNonFungiblePositionManager(
      token0,
      token1,
      _params._amount0Desired,
      _params._amount1Desired
    );

    // Increase liquidity at the position.
    (uint128 liquidity, , ) = uniswapV3PositionManager.increaseLiquidity(
      INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId: tokenId,
        amount0Desired: _params._amount0Desired,
        amount1Desired: _params._amount1Desired,
        amount0Min: _params._amount0Min,
        amount1Min: _params._amount1Min,
        deadline: block.timestamp
      })
    );

    // Mint wrapper tokens corresponding to the liquidity added.
    _mintTokens(_params._positionWrapper, tokenId, liquidity);

    // Calculate token balances after the operation to determine any remaining dust.
    balance0After = IERC20Upgradeable(token0).balanceOf(address(this));
    balance1After = IERC20Upgradeable(token1).balanceOf(address(this));

    // Return any dust to the caller.
    _returnDust(
      _params._dustReceiver,
      token0,
      token1,
      balance0After - balance0Before,
      balance1After - balance1Before
    );

    emit LiquidityIncreased(msg.sender, liquidity);
  }

  /**
   * @notice Decreases liquidity for an existing Uniswap V3 position and burns the corresponding wrapper tokens.
   * @dev This function allows a holder of wrapper tokens to reduce their position in the Uniswap pool. It decreases the
   *      specified amount of liquidity from the Uniswap V3 position, burns the corresponding amount of wrapper tokens,
   *      and returns the underlying tokens to the caller. It ensures that the caller cannot remove more liquidity than
   *      they hold in wrapper tokens.
   * @param _positionWrapper The address of the position wrapper contract, which represents the Uniswap V3 position.
   * @param _withdrawalAmount The amount of wrapper tokens that represent the liquidity to be removed.
   * @param _amount0Min The minimum amount of token0 that must be returned from the liquidity decrease to prevent front-running.
   * @param _amount1Min The minimum amount of token1 that must be returned from the liquidity decrease to prevent front-running.
   */
  function decreaseLiquidity(
    IPositionWrapper _positionWrapper,
    uint256 _withdrawalAmount,
    uint256 _amount0Min,
    uint256 _amount1Min,
    // swap params
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external nonReentrant {
    uint256 tokenId = _positionWrapper.tokenId();

    // Ensure the withdrawal amount is greater than zero.
    if (_withdrawalAmount == 0) revert ErrorLibrary.AmountCannotBeZero();

    // Ensure the caller has sufficient wrapper tokens to cover the withdrawal amount.
    if (_withdrawalAmount > _positionWrapper.balanceOf(msg.sender))
      revert ErrorLibrary.InsufficientBalance();

    uint256 totalSupplyBeforeBurn = _positionWrapper.totalSupply();

    // Burn the wrapper tokens equivalent to the withdrawn liquidity.
    _positionWrapper.burn(msg.sender, _withdrawalAmount);

    // If there are still wrapper tokens in circulation, collect fees and reinvest them.
    if (totalSupplyBeforeBurn > 0)
      _collectFeesAndReinvest(
        _positionWrapper,
        tokenId,
        _positionWrapper.token0(),
        _positionWrapper.token1(),
        tokenIn,
        tokenOut,
        amountIn
      );

    // Calculate the proportionate amount of liquidity to decrease based on the total supply and withdrawal amount.
    uint128 liquidityToDecrease = MathUtils.safe128(
      (_getExistingLiquidity(tokenId) * _withdrawalAmount) /
        totalSupplyBeforeBurn
    );

    // Execute the decrease liquidity operation and collect the freed assets.
    decreaseLiquidityAndCollect(
      liquidityToDecrease,
      tokenId,
      _amount0Min,
      _amount1Min,
      msg.sender
    );

    emit LiquidityDecreased(msg.sender, liquidityToDecrease);
  }

  /**
   * @notice Approves the Non-Fungible Position Manager to spend tokens on behalf of this contract.
   * @param _token0 The address of token0.
   * @param _token1 The address of token1.
   * @param _amount0 The amount of token0 to approve.
   * @param _amount1 The amount of token1 to approve.
   */
  function _approveNonFungiblePositionManager(
    address _token0,
    address _token1,
    uint256 _amount0,
    uint256 _amount1
  ) internal {
    // Reset the allowance for token0 to zero before setting it to a new value

    TransferHelper.safeApprove(_token0, address(uniswapV3PositionManager), 0);
    TransferHelper.safeApprove(_token1, address(uniswapV3PositionManager), 0);

    // Reset the allowance for token1 to zero before setting it to a new value
    TransferHelper.safeApprove(
      _token0,
      address(uniswapV3PositionManager),
      _amount0
    );
    TransferHelper.safeApprove(
      _token1,
      address(uniswapV3PositionManager),
      _amount1
    );
  }

  /**
   * @notice Transfers specified amounts of token0 and token1 from the sender to this contract.
   * @dev Uses the TransferHelper library to safely transfer tokens from the function caller to this contract.
   *      This function is typically used to prepare tokens for liquidity operations in Uniswap V3.
   * @param _token0 The contract address of the first token (token0).
   * @param _token1 The contract address of the second token (token1).
   * @param _amount0 The amount of token0 to transfer from the sender to this contract.
   * @param _amount1 The amount of token1 to transfer from the sender to this contract.
   */
  function _transferTokensFromSender(
    address _token0,
    address _token1,
    uint256 _amount0,
    uint256 _amount1
  ) internal {
    // Safely transfer token0 from the sender to this contract.

    TransferHelper.safeTransferFrom(
      _token0,
      msg.sender,
      address(this),
      _amount0
    );

    // Safely transfer token1 from the sender to this contract.
    TransferHelper.safeTransferFrom(
      _token1,
      msg.sender,
      address(this),
      _amount1
    );
  }

  /**
   * @notice Returns any excess tokens to the sender after operations are completed.
   * @param _token0 The address of token0.
   * @param _token1 The address of token1.
   * @param _amount0 The amount of token0 to return.
   * @param _amount1 The amount of token1 to return.
   */
  function _returnDust(
    address _dustReceiver,
    address _token0,
    address _token1,
    uint256 _amount0,
    uint256 _amount1
  ) internal {
    if (_amount0 > 0)
      TransferHelper.safeTransfer(_token0, _dustReceiver, _amount0);
    if (_amount1 > 0)
      TransferHelper.safeTransfer(_token1, _dustReceiver, _amount1);
  }

  /**
   * @notice Mints wrapper tokens corresponding to the provided liquidity in the Uniswap V3 position.
   * @dev Calculates the amount of wrapper tokens to mint based on the liquidity added.
   *      If it's the first time liquidity is added, the mint amount equals the liquidity.
   *      Otherwise, it calculates a share based on existing liquidity.
   * @param _positionWrapper The position wrapper associated with the Uniswap V3 position.
   * @param _tokenId The ID of the Uniswap V3 position token.
   * @param _liquidity The amount of liquidity that has been added to the position.
   */
  function _mintTokens(
    IPositionWrapper _positionWrapper,
    uint256 _tokenId,
    uint128 _liquidity
  ) internal {
    uint256 totalSupply = _positionWrapper.totalSupply();
    uint256 mintAmount;

    // If this is the first liquidity being added, mint tokens equal to the amount of liquidity.
    if (totalSupply == 0) {
      mintAmount = _liquidity;
    } else {
      // Calculate the proportionate amount of tokens to mint based on the added liquidity.
      uint256 userShare = (_liquidity * ONE_ETH_IN_WEI) /
        _getExistingLiquidity(_tokenId);
      mintAmount = _calculateMintAmount(userShare, totalSupply);
    }

    // Mint the calculated amount of wrapper tokens to the sender.
    _positionWrapper.mint(msg.sender, mintAmount);
  }

  /**
   * @notice Decreases liquidity and collects the tokens from a Uniswap V3 position.
   * @param _liquidityToDecrease The amount of liquidity to decrease.
   * @param _tokenId The ID of the Uniswap V3 position.
   * @param _amount0Min The minimum amount of token0 that must be returned.
   * @param _amount1Min The minimum amount of token1 that must be returned.
   * @param _recipient The address that will receive the withdrawn tokens.
   */
  function decreaseLiquidityAndCollect(
    uint128 _liquidityToDecrease,
    uint256 _tokenId,
    uint256 _amount0Min,
    uint256 _amount1Min,
    address _recipient
  ) internal {
    // Decrease liquidity at Uniswap V3 Nonfungible Position Manager
    uniswapV3PositionManager.decreaseLiquidity(
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: _tokenId,
        liquidity: _liquidityToDecrease,
        amount0Min: _amount0Min,
        amount1Min: _amount1Min,
        deadline: block.timestamp
      })
    );

    // Collect the tokens released from the decrease in liquidity
    uniswapV3PositionManager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _tokenId,
        recipient: _recipient,
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  /**
   * @notice Collects trading fees accrued in a Uniswap V3 position and reinvests them by increasing liquidity.
   * @dev This function first collects fees generated by the Uniswap V3 position. If the collected fees exceed
   *      the defined minimum thresholds for both tokens, it reinvests these by adding them back as liquidity
   *      to the same position.
   * @param _tokenId The ID of the Uniswap V3 position from which fees are to be collected.
   * @param _token0 The address of the first token in the Uniswap V3 position.
   * @param _token1 The address of the second token in the Uniswap V3 position.
   */
  function _collectFeesAndReinvest(
    IPositionWrapper _positionWrapper,
    uint256 _tokenId,
    address _token0,
    address _token1,
    // swap params
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) internal {
    // Collect all available fees for the position to this contract
    uniswapV3PositionManager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _tokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );

    (int24 tickLower, int24 tickUpper) = _getTicksFromPosition(_tokenId);

    (uint256 feeCollectedT0, uint256 feeCollectedT1) = _swapTokensForAmount(
      WrapperFunctionParameters.SwapParams({
        _positionWrapper: _positionWrapper,
        _tokenId: _tokenId,
        _amountIn: amountIn,
        _token0: _token0,
        _token1: _token1,
        _tokenIn: tokenIn,
        _tokenOut: tokenOut,
        _tickLower: tickLower,
        _tickUpper: tickUpper
      })
    );

    // Reinvest fees if they exceed the minimum threshold for reinvestment
    if (
      feeCollectedT0 > MIN_REINVESTMENT_AMOUNT &&
      feeCollectedT1 > MIN_REINVESTMENT_AMOUNT
    ) {
      // Increase liquidity using all collected fees
      uniswapV3PositionManager.increaseLiquidity(
        INonfungiblePositionManager.IncreaseLiquidityParams({
          tokenId: _tokenId,
          amount0Desired: feeCollectedT0,
          amount1Desired: feeCollectedT1,
          amount0Min: 1,
          amount1Min: 1,
          deadline: block.timestamp
        })
      );
    }
  }

  /**
   * @notice Retrieves the current liquidity amount for a given position.
   * @param _tokenId The ID of the position.
   * @return existingLiquidity The current amount of liquidity in the position.
   */
  function _getExistingLiquidity(
    uint256 _tokenId
  ) internal view virtual returns (uint128 existingLiquidity);

  function _swapTokensForAmount(
    WrapperFunctionParameters.SwapParams memory _params
  ) internal virtual returns (uint256, uint256);

  function _getTicksFromPosition(
    uint256 _tokenId
  ) internal view virtual returns (int24, int24);
}
