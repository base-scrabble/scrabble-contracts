
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address superAdmin;
        string usdtName;
        string usdtSymbol;
        uint256 usdtSupply;
        string usdcName;
        string usdcSymbol;
        uint256 usdcSupply;
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        if (block.chainid == 11155111) {
            // Ethereum Sepolia
            return NetworkConfig({
                superAdmin: vm.envAddress("ETHEREUM_SEPOLIA_SUPER_ADMIN"),
                usdtName: "Tether USD",
                usdtSymbol: "USDT",
                usdtSupply: 1_000_000 * 10**6, // 1M USDT, 6 decimals
                usdcName: "USD Coin",
                usdcSymbol: "USDC",
                usdcSupply: 1_000_000 * 10**6 // 1M USDC, 6 decimals
            });
        } else if (block.chainid == 84532) {
            // Base Sepolia
            return NetworkConfig({
                superAdmin: msg.sender, // Use deployer's address
                usdtName: "Tether USD",
                usdtSymbol: "USDT",
                usdtSupply: 1_000_000 * 10**6, // 1M USDT, 6 decimals
                usdcName: "USD Coin",
                usdcSymbol: "USDC",
                usdcSupply: 1_000_000 * 10**6 // 1M USDC, 6 decimals
            });
        } else if (block.chainid == 8453) {
            // Base Mainnet
            return NetworkConfig({
                superAdmin: vm.envAddress("BASE_MAINNET_SUPER_ADMIN"),
                usdtName: "Tether USD",
                usdtSymbol: "USDT",
                usdtSupply: 1_000_000 * 10**6, // 1M USDT, 6 decimals
                usdcName: "USD Coin",
                usdcSymbol: "USDC",
                usdcSupply: 1_000_000 * 10**6 // 1M USDC, 6 decimals
            });
        } else {
            // Local Anvil or other networks
            return NetworkConfig({
                superAdmin: vm.envAddress("DEFAULT_SUPER_ADMIN"),
                usdtName: "Tether USD",
                usdtSymbol: "USDT",
                usdtSupply: 1_000_000 * 10**6, // 1M USDT, 6 decimals
                usdcName: "USD Coin",
                usdcSymbol: "USDC",
                usdcSupply: 1_000_000 * 10**6 // 1M USDC, 6 decimals
            });
        }
    }
}