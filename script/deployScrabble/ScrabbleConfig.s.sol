// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

contract ScrabbleConfig is Script {
    struct NetworkConfig {
        address superAdmin;
        address wallet;
        address submitter;
        address backendSigner;
        address usdt;
        address usdc;
        address ethUsdPriceFeed;
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        if (block.chainid == 11155111) {
            // Ethereum Sepolia
            return NetworkConfig({
                superAdmin: vm.envAddress("ETHEREUM_SEPOLIA_SUPER_ADMIN"),
                wallet: vm.envAddress("ETHEREUM_SEPOLIA_WALLET"),
                submitter: vm.envAddress("ETHEREUM_SEPOLIA_SUBMITTER"),
                backendSigner: vm.envAddress("ETHEREUM_SEPOLIA_BACKEND_SIGNER"),
                usdt: vm.envAddress("ETHEREUM_SEPOLIA_USDT"),
                usdc: vm.envAddress("ETHEREUM_SEPOLIA_USDC"),
                ethUsdPriceFeed: vm.envAddress("ETHEREUM_SEPOLIA_PRICE_FEED")
            });
        } else if (block.chainid == 84532) {
            // Base Sepolia
            return NetworkConfig({
                superAdmin: vm.envAddress("BASE_SEPOLIA_SUPER_ADMIN"),
                wallet: vm.envAddress("BASE_SEPOLIA_WALLET_ADDRESS"),
                submitter: vm.envAddress("BASE_SEPOLIA_SUBMITTER"),
                backendSigner: vm.envAddress("BASE_SEPOLIA_BACKEND_SIGNER"),
                usdt: vm.envAddress("WALLET_USDT_ADDRESS"),
                usdc: vm.envAddress("WALLET_USDC_ADDRESS"),
                ethUsdPriceFeed: vm.envAddress("BASE_SEPOLIA_PRICE_FEED")
            });
        } else if (block.chainid == 8453) {
            // Base Mainnet
            return NetworkConfig({
                superAdmin: vm.envAddress("BASE_MAINNET_SUPER_ADMIN"),
                wallet: vm.envAddress("BASE_MAINNET_WALLET"),
                submitter: vm.envAddress("BASE_MAINNET_SUBMITTER"),
                backendSigner: vm.envAddress("BASE_MAINNET_BACKEND_SIGNER"),
                usdt: vm.envAddress("BASE_MAINNET_USDT"),
                usdc: vm.envAddress("BASE_MAINNET_USDC"),
                ethUsdPriceFeed: vm.envAddress("BASE_MAINNET_PRICE_FEED")
            });
        } else {
            // Local Anvil or other networks
            return NetworkConfig({
                superAdmin: vm.envAddress("DEFAULT_SUPER_ADMIN"),
                wallet: vm.envAddress("DEFAULT_WALLET"),
                submitter: vm.envAddress("DEFAULT_SUBMITTER"),
                backendSigner: vm.envAddress("DEFAULT_BACKEND_SIGNER"),
                usdt: vm.envAddress("DEFAULT_USDT"),
                usdc: vm.envAddress("DEFAULT_USDC"),
                ethUsdPriceFeed: vm.envAddress("DEFAULT_PRICE_FEED")
            });
        }
    }
}
