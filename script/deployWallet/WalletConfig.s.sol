
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

contract WalletConfig is Script {
    struct NetworkConfig {
        address superAdmin;
        address priceFeed;
        address usdt;
        address usdc;
        address backendSigner;
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        if (block.chainid == 11155111) {
            // Ethereum Sepolia
            return NetworkConfig({
                superAdmin: vm.envAddress("ETHEREUM_SEPOLIA_SUPER_ADMIN"),
                priceFeed: vm.envAddress("ETHEREUM_SEPOLIA_PRICE_FEED"),
                usdt: vm.envAddress("ETHEREUM_SEPOLIA_USDT"),
                usdc: vm.envAddress("ETHEREUM_SEPOLIA_USDC"),
                backendSigner: vm.envAddress("ETHEREUM_SEPOLIA_BACKEND_SIGNER")
            });
        } else if (block.chainid == 84532) {
            // Base Sepolia
            return NetworkConfig({
                superAdmin: vm.envAddress("BASE_SEPOLIA_SUPER_ADMIN"),
                priceFeed: vm.envAddress("BASE_SEPOLIA_PRICE_FEED"),
                usdt: vm.envAddress("BASE_SEPOLIA_USDT"),
                usdc: vm.envAddress("BASE_SEPOLIA_USDC"),
                backendSigner: vm.envAddress("BASE_SEPOLIA_BACKEND_SIGNER")
            });
        } else if (block.chainid == 8453) {
            // Base Mainnet
            return NetworkConfig({
                superAdmin: vm.envAddress("BASE_MAINNET_SUPER_ADMIN"),
                priceFeed: vm.envAddress("BASE_MAINNET_PRICE_FEED"),
                usdt: vm.envAddress("BASE_MAINNET_USDT"),
                usdc: vm.envAddress("BASE_MAINNET_USDC"),
                backendSigner: vm.envAddress("BASE_MAINNET_BACKEND_SIGNER")
            });
        } else {
            // Local Anvil or other networks
            return NetworkConfig({
                superAdmin: vm.envAddress("DEFAULT_SUPER_ADMIN"),
                priceFeed: vm.envAddress("DEFAULT_PRICE_FEED"),
                usdt: vm.envAddress("DEFAULT_USDT"),
                usdc: vm.envAddress("DEFAULT_USDC"),
                backendSigner: vm.envAddress("DEFAULT_BACKEND_SIGNER")
            });
        }
    }
}