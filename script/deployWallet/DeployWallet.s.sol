
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Wallet} from "../../src/wallet/Wallet.sol";
import {WalletConfig} from "./WalletConfig.s.sol";
import {console} from "forge-std/console.sol";

contract DeployWallet is Script {
    function run() external returns (Wallet) {
        // Initialize configuration
        WalletConfig walletConfig = new WalletConfig();
        WalletConfig.NetworkConfig memory config = walletConfig.getNetworkConfig();

        // Validate inputs
        require(config.superAdmin != address(0), "Invalid superAdmin address");
        require(config.priceFeed != address(0), "Invalid priceFeed address");
        require(config.usdt != address(0), "Invalid USDT address");
        require(config.usdc != address(0), "Invalid USDC address");
        require(config.backendSigner != address(0), "Invalid backendSigner address");

        console.log("Deploying Wallet with:");
        console.log("  superAdmin:", config.superAdmin);
        console.log("  priceFeed:", config.priceFeed);
        console.log("  USDT:", config.usdt);
        console.log("  USDC:", config.usdc);
        console.log("  backendSigner:", config.backendSigner);

        // Start broadcasting
        vm.startBroadcast();

        // Deploy Wallet
        Wallet wallet = new Wallet(
            config.priceFeed,
            config.superAdmin,
            config.usdt,
            config.backendSigner,
            config.usdc
        );
        console.log("Wallet deployed to:", address(wallet));

        // Verify initialization
        console.log("Wallet admin matches superAdmin:", wallet.hasRole(keccak256("ADMIN_ROLE"), config.superAdmin));
        console.log("Wallet USDT address:", wallet.USDT());
        console.log("Wallet USDC address:", wallet.USDC());

        // Stop broadcasting
        vm.stopBroadcast();

        return wallet;
    }
}