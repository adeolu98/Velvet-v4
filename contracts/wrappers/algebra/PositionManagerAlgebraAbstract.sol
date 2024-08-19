// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {PositionManagerAbstract, IPositionWrapper, WrapperFunctionParameters, ErrorLibrary, IERC20Upgradeable} from "../abstract/PositionManagerAbstract.sol";
import {INonfungiblePositionManager} from "./INonfungiblePositionManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IFactory} from "./IFactory.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IProtocolConfig} from "../../config/protocol/IProtocolConfig.sol";

/**
 * @title PositionManagerAbstract
 * @dev Abstract contract for managing Uniswap V3 positions and representing them as ERC20 tokens.
 * This contract allows managing liquidity in Uniswap V3 positions through a tokenized interface.
 */
abstract contract PositionManagerAbstractAlgebra is PositionManagerAbstract {
  IProtocolConfig internal protocolConfig;

  function PositionManagerAbstractAlgebra_init(
    address _nonFungiblePositionManagerAddress,
    address _protocolConfig,
    address _assetManagerConfig,
    address _accessController
  ) internal {
    PositionManagerAbstract__init(
      _nonFungiblePositionManagerAddress,
      _assetManagerConfig,
      _accessController
    );

    protocolConfig = IProtocolConfig(_protocolConfig);
  }

  /**
   * @notice Mints a new Uniswap V3 position along with corresponding ERC-20 wrapper tokens.
   * @dev This function orchestrates the creation of a new liquidity position on Uniswap V3 and also creates a new
   *      wrapper token that represents this position. It handles creating a new wrapper, initializing the position with
   *      the specified liquidity, and returning the address of the new wrapper.
   * @param _token0 The address of the first token (token0) for the new liquidity position.
   * @param _token1 The address of the second token (token1) for the new liquidity position.
   * @param _name The desired name for the new wrapper token.
   * @param _symbol The desired symbol for the new wrapper token.
   * @param params A struct containing parameters necessary for liquidity provision including:
   *        amount of token0 and token1 desired, minimum amounts to prevent slippage, and other necessary details.
   * @return The address of the newly created wrapper position that now represents the staked liquidity tokens.
   */
  function createNewWrapperPositionAndDeposit(
    address _dustReceiver,
    address _token0,
    address _token1,
    string memory _name,
    string memory _symbol,
    WrapperFunctionParameters.PositionMintParamsThena memory params
  ) external nonReentrant returns (address) {
    // Create and initialize a new wrapper position
    IPositionWrapper positionWrapper = createNewWrapperPosition(
      _token0,
      _token1,
      _name,
      _symbol,
      params._tickLower,
      params._tickUpper
    );

    // Initialize the Uniswap V3 position with specified liquidity and mint wrapper tokens
    _initializePositionAndDeposit(_dustReceiver, positionWrapper, params);

    // Return the address of the new wrapper position
    return address(positionWrapper);
  }

  /**
   * @notice Initializes a new Uniswap V3 position with liquidity for the first time and mints wrapper tokens.
   * @dev This function is used to start a new liquidity position in Uniswap V3 using the tokens specified in the parameters.
   *      It handles the transfer of initial liquidity tokens from the sender, mints the position on Uniswap, and then mints
   *      the corresponding wrapper tokens. It also ensures that no initial minting has occurred previously for the given position.
   *      This function manages token balances to ensure only the necessary tokens are used and any excess is returned (dust).
   * @param _positionWrapper The wrapper interface for the Uniswap V3 position which facilitates interaction with the core contract.
   * @param params The liquidity parameters including the desired amounts of token0 and token1, and slippage protections.
   */
  function initializePositionAndDeposit(
    address _dustReceiver,
    IPositionWrapper _positionWrapper,
    WrapperFunctionParameters.InitialMintParams memory params
  ) external nonReentrant {
    // Mint the new Uniswap V3 position using the provided liquidity parameters.
    _initializePositionAndDeposit(
      _dustReceiver,
      _positionWrapper,
      WrapperFunctionParameters.PositionMintParamsThena({
        _amount0Desired: params._amount0Desired,
        _amount1Desired: params._amount1Desired,
        _amount0Min: params._amount0Min,
        _amount1Min: params._amount1Min,
        _tickLower: _positionWrapper.initialTickLower(),
        _tickUpper: _positionWrapper.initialTickUpper()
      })
    );
  }

  /**
   * @notice Updates the range and fee tier of an existing Uniswap V3 position represented by a wrapper.
   * @dev This function removes all liquidity from an existing position, then re-establishes the position
   *      with new range and fee parameters. It is intended to adjust positions to more efficient or desirable
   *      price ranges based on market conditions or strategy changes.
   * @param _positionWrapper The wrapper contract that encapsulates the Uniswap V3 position.
   * @param _tickLower The new lower bound of the price range for the position.
   * @param _tickUpper The new upper bound of the price range for the position.
   */
  function updateRange(
    IPositionWrapper _positionWrapper,
    int24 _tickLower,
    int24 _tickUpper
  ) external onlyAssetManager {
    uint256 tokenId = _positionWrapper.tokenId();

    address token0 = _positionWrapper.token0();
    address token1 = _positionWrapper.token1();

    // Retrieve existing liquidity to be removed.
    uint128 existingLiquidity = _getExistingLiquidity(tokenId);

    // Remove all liquidity and collect the underlying tokens to this contract.
    decreaseLiquidityAndCollect(
      existingLiquidity,
      tokenId,
      1, // Minimal acceptable token amounts set to 1 as a formality; all liquidity is being removed.
      1,
      address(this)
    );

    // Mint a new position with the adjusted range and fee, using the tokens just collected.
    (uint256 newTokenId, ) = _mintNewUniswapPosition(
      _positionWrapper,
      WrapperFunctionParameters.PositionMintParamsThena({
        _amount0Desired: IERC20Upgradeable(token0).balanceOf(address(this)),
        _amount1Desired: IERC20Upgradeable(token1).balanceOf(address(this)),
        _amount0Min: 1,
        _amount1Min: 1,
        _tickLower: _tickLower,
        _tickUpper: _tickUpper
      })
    );

    // Update the wrapper with the new token ID to reflect the repositioned state.
    _positionWrapper.updateTokenId(newTokenId);

    emit PriceRangeUpdated(address(_positionWrapper), _tickLower, _tickUpper);
  }

  /**
   * @notice Creates and initializes a new wrapper position by cloning a predefined base implementation.
   * @dev Clones an existing position wrapper contract, initializes it with specific token addresses and metadata, and registers it.
   *      This method ensures that only whitelisted tokens can be used to create new positions if whitelisting is enabled.
   * @param _token0 The address of the first token (token0) for the new position.
   * @param _token1 The address of the second token (token1) for the new position.
   * @param _name The name to assign to the new wrapper token.
   * @param _symbol The symbol to assign to the new wrapper token.
   * @return positionWrapper The newly created and initialized position wrapper instance.
   */
  function createNewWrapperPosition(
    address _token0,
    address _token1,
    string memory _name,
    string memory _symbol,
    int24 _tickLower,
    int24 _tickUpper
  ) public onlyAssetManager returns (IPositionWrapper) {
    // Check if both tokens are whitelisted if the token whitelisting feature is enabled.
    if (
      assetManagementConfig.tokenWhitelistingEnabled() &&
      (!assetManagementConfig.whitelistedTokens(_token0) ||
        !assetManagementConfig.whitelistedTokens(_token1))
    ) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }

    // Clone the base implementation of a position wrapper.
    IPositionWrapper positionWrapper = IPositionWrapper(
      Clones.clone(protocolConfig.positionWrapperBaseImplementation())
    );

    (address token0, address token1) = _getTokensInPoolOrder(_token0, _token1);

    // Initialize the cloned position wrapper with token addresses, name, and symbol.
    positionWrapper.init(address(this), token0, token1, _name, _symbol);

    // Set init values for the position wrapper
    positionWrapper.setIntitialParameters(0, _tickLower, _tickUpper);

    // Register the new wrapper in the deployed position wrappers list and mark it as a valid wrapper.
    deployedPositionWrappers.push(address(positionWrapper));
    isWrappedPosition[address(positionWrapper)] = true;

    emit NewPositionCreated(address(positionWrapper), _token0, _token1);

    return positionWrapper;
  }

  function _initializePositionAndDeposit(
    address _dustReceiver,
    IPositionWrapper _positionWrapper,
    WrapperFunctionParameters.PositionMintParamsThena memory params
  ) internal {
    address token0 = _positionWrapper.token0();
    address token1 = _positionWrapper.token1();

    // Record balances of token0 and token1 before the transfer to calculate dust later.
    uint256 balance0Before = IERC20Upgradeable(token0).balanceOf(address(this));
    uint256 balance1Before = IERC20Upgradeable(token1).balanceOf(address(this));

    // Transfer the specified amounts of token0 and token1 from the sender to this contract.
    _transferTokensFromSender(
      token0,
      token1,
      params._amount0Desired,
      params._amount1Desired
    );

    // Mint the new Uniswap V3 position using the provided liquidity parameters.
    (uint256 tokenId, uint128 liquidity) = _mintNewUniswapPosition(
      _positionWrapper,
      params
    );

    // Set the token ID of the newly minted Uniswap V3 position in the wrapper.
    _positionWrapper.setTokenId(tokenId);

    // Mint wrapper tokens equivalent to the amount of liquidity added to the Uniswap position.
    _positionWrapper.mint(msg.sender, liquidity);

    // Calculate the difference in token balances to determine dust.
    uint256 balance0After = IERC20Upgradeable(token0).balanceOf(address(this));
    uint256 balance1After = IERC20Upgradeable(token1).balanceOf(address(this));

    // Return any excess tokens (dust) that weren't used in liquidity addition back to the sender.
    _returnDust(
      _dustReceiver,
      token0,
      token1,
      balance0After - balance0Before,
      balance1After - balance1Before
    );

    emit PositionInitializedAndDeposited(address(_positionWrapper));
  }

  /**
   * @notice Mints a new Uniswap V3 position with specified liquidity parameters.
   * @dev This function handles the process of minting a new liquidity position directly on Uniswap V3.
   *      It first approves the Uniswap V3 Non-Fungible Position Manager to use the required amounts of token0 and token1.
   *      Then, it mints the position with the desired parameters, setting the contract as the recipient of the position's NFT.
   *      This function is crucial for initializing positions that represent liquidity in specific token pairs.
   * @param _positionWrapper The interface wrapper around the Uniswap V3 position, providing token addresses and other utilities.
   * @param params The parameters struct containing all necessary details to mint the position such as:
   *        token amounts desired, minimum acceptable amounts (to guard against slippage), fee tier, tick boundaries, and deadline.
   * @return tokenId The unique identifier of the newly created Uniswap V3 position.
   * @return liquidity The amount of liquidity that was successfully added to the position.
   */
  function _mintNewUniswapPosition(
    IPositionWrapper _positionWrapper,
    WrapperFunctionParameters.PositionMintParamsThena memory params
  ) internal returns (uint256 tokenId, uint128 liquidity) {
    address token0 = _positionWrapper.token0();
    address token1 = _positionWrapper.token1();

    // Approve the Uniswap V3 Non-Fungible Position Manager to use the tokens needed for the new position.
    _approveNonFungiblePositionManager(
      token0,
      token1,
      params._amount0Desired,
      params._amount1Desired
    );

    // Mint the new position using the specified parameters and return the tokenId and liquidity amount.
    (tokenId, liquidity, , ) = INonfungiblePositionManager(
      address(uniswapV3PositionManager)
    ).mint(
        INonfungiblePositionManager.MintParams({
          token0: token0,
          token1: token1,
          tickLower: params._tickLower,
          tickUpper: params._tickUpper,
          amount0Desired: params._amount0Desired,
          amount1Desired: params._amount1Desired,
          amount0Min: params._amount0Min,
          amount1Min: params._amount1Min,
          recipient: address(this),
          deadline: block.timestamp
        })
      );
  }

  /**
   * @notice Retrieves the current liquidity amount for a given position.
   * @param _tokenId The ID of the position.
   * @return existingLiquidity The current amount of liquidity in the position.
   */
  function _getExistingLiquidity(
    uint256 _tokenId
  ) internal view override returns (uint128 existingLiquidity) {
    (, , , , , , existingLiquidity, , , , ) = INonfungiblePositionManager(
      address(uniswapV3PositionManager)
    ).positions(_tokenId);
  }

  function _getTokensInPoolOrder(
    address _token0,
    address _token1
  ) internal view returns (address token0, address token1) {
    IFactory factory = IFactory(uniswapV3PositionManager.factory());
    IPool pool = IPool(factory.poolByPair(_token0, _token1));

    token0 = pool.token0();
    token1 = pool.token1();
  }
}
