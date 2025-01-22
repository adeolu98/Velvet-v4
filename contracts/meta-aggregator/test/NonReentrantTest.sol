// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "../interfaces/IMetaAggregatorManager.sol";
import "../interfaces/IMetaAggregatorSwapContract.sol";

contract NonReentrantTest {
    function receiveCall(
        address callerAddress,
        IMetaAggregatorManager.SwapERC20Params calldata params
    ) external payable {
        IMetaAggregatorManager(callerAddress).swap(params);
    }

    function receiverCallETH(
        address callerAddress,
        IMetaAggregatorSwapContract.SwapETHParams calldata params
    ) external payable {
        IMetaAggregatorSwapContract(callerAddress).swapETH(params);
    }

    function receiverCallToken(
        address callerAddress,
        IMetaAggregatorSwapContract.SwapERC20Params calldata params
    ) external payable {
        IMetaAggregatorSwapContract(callerAddress).swapERC20(params);
    }
}
