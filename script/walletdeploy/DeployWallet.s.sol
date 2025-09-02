// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Wallet} from "../../src/wallet/Wallet.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployWallet is Script {
    function run() external returns (Wallet) {
        Wallet wallet;
        HelperConfig helperConfig = new HelperConfig();

        (address priceFeed, address superAdmin, address usdt, address backendSigner, address usdc) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        wallet = new Wallet(priceFeed, superAdmin, usdt, backendSigner, usdc);
        vm.stopBroadcast();

        return (wallet);
    }
}
