// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import {AccessManager} from "../../src/access/AccessManager.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address superAdmin;
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        if (block.chainid == 11155111) {
            // Ethereum Sepolia
            return NetworkConfig({superAdmin: vm.envAddress("ETHEREUM_SEPOLIA_SUPER_ADMIN")});
        } else if (block.chainid == 84532) {
            // Base Sepolia
            return NetworkConfig({superAdmin: vm.envAddress("BASE_SEPOLIA_SUPER_ADMIN")});
        } else if (block.chainid == 8453) {
            // Base Mainnet
            return NetworkConfig({superAdmin: vm.envAddress("BASE_MAINNET_SUPER_ADMIN")});
        } else {
            // Local Anvil or other networks
            return NetworkConfig({superAdmin: vm.envAddress("DEFAULT_SUPER_ADMIN")});
        }
    }
}
