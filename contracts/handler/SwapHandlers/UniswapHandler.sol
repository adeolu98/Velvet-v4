// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {ISwapHandler} from "../ISwapHandler.sol";

contract UniswapHandler is ISwapHandler {
  address immutable ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

  function swapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    address to,
    uint amountIn,
    uint amountOut,
    uint fee
  ) public view returns (bytes memory data) {
    bytes memory path = abi.encodePacked(
      tokenIn, // Address of the input token
      fee, // Pool fee (0.3%)
      tokenOut // Address of the output token
    );

    bytes memory encodedParams = abi.encode(
      path,
      to,
      block.timestamp + 15,
      amountIn,
      amountOut
    );

    data = abi.encodeWithSelector(
      bytes4(keccak256("exactInput((bytes,address,uint256,uint256,uint256))")),
      encodedParams
    );
  }

  function swapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    address to,
    uint amountIn,
    uint amountOut,
    uint fee
  ) public view returns (bytes memory data) {
    bytes memory path = abi.encodePacked(
      tokenIn, // Address of the input token
      fee, // Pool fee (0.3%)
      tokenOut // Address of the output token
    );

    bytes memory encodedParams = abi.encode(
      path,
      to,
      block.timestamp + 15,
      amountIn,
      amountOut
    );

    data = abi.encodeWithSelector(
      bytes4(keccak256("exactOutput((bytes,address,uint256,uint256,uint256))")),
      encodedParams
    );
  }

  function getRouterAddress() public view returns (address) {
    return ROUTER_ADDRESS;
  }
}
