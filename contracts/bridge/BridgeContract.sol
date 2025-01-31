// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IDlnSource } from "./IDlnSource.sol";
import { DlnOrderLib } from "./DlnOrderLib.sol";

import { TransferHelper } from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "hardhat/console.sol";

contract BridgeContract {
  address constant dlnSourceAddress =
    0xeF4fB24aD0916217251F553c0596F8Edc630EB66;

  function bridge() external payable {
    // preparing an order
    DlnOrderLib.OrderCreation memory orderCreation;
    orderCreation.giveTokenAddress = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base
    orderCreation.giveAmount = 250000000; // 250 USDC
    orderCreation.takeTokenAddress = abi.encodePacked(
      0xbA2aE424d960c26247Dd6c32edC70B295c744C43
    );
    orderCreation.takeAmount = 2497400000000; // 249,740 DOGE
    orderCreation.takeChainId = 56; // BNB Chain
    orderCreation.receiverDst = abi.encodePacked(
      0x74A53d748e9BBED5380ff134889A02EffDc4345a
    );
    orderCreation
      .givePatchAuthoritySrc = 0x74A53d748e9BBED5380ff134889A02EffDc4345a;
    orderCreation.orderAuthorityAddressDst = abi.encodePacked(
      0x74A53d748e9BBED5380ff134889A02EffDc4345a
    );
    orderCreation.allowedTakerDst = bytes("");
    orderCreation.externalCall = bytes("");
    orderCreation.allowedCancelBeneficiarySrc = bytes("");

    // getting the protocol fee
    uint protocolFee = IDlnSource(dlnSourceAddress).globalFixedNativeFee();

    console.log(
      "orderCreation.giveTokenAddress",
      orderCreation.giveTokenAddress
    );
    console.log("orderCreation.giveAmount", orderCreation.giveAmount);

    // giving approval
    TransferHelper.safeApprove(
      orderCreation.giveTokenAddress,
      dlnSourceAddress,
      orderCreation.giveAmount
    );

    console.log("after approval");

    // placing an order using createSaltedOrder instead of createOrder
    bytes32 orderId = IDlnSource(dlnSourceAddress).createSaltedOrder{
      value: protocolFee
    }(orderCreation, 0, bytes(""), uint32(0), bytes(""), bytes("")); // Match interface parameters
  }
}
