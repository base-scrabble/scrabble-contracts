// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {AccessManager} from "../../src/access/AccessManager.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console} from "forge-std/console.sol";

contract DeployAccessManager is Script {
    function run() external returns (AccessManager) {
        // Initialize configuration
        HelperConfig accessConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = accessConfig.getNetworkConfig();

        // Validate superAdmin
        require(config.superAdmin != address(0), "Invalid superAdmin address");
        console.log("Deploying AccessManager with superAdmin:", config.superAdmin);

        // Start broadcasting
        vm.startBroadcast();

        // Deploy AccessManager
        AccessManager accessManager = new AccessManager(config.superAdmin);
        console.log("AccessManager deployed to:", address(accessManager));

        // Verify roles
        bytes32 DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
        bytes32 ADMIN_ROLE = keccak256("ADMIN_ROLE");
        bytes32 TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");

        bool hasDefaultAdminRole = accessManager.hasRole(DEFAULT_ADMIN_ROLE, config.superAdmin);
        bool hasAdminRole = accessManager.hasRole(ADMIN_ROLE, config.superAdmin);
        bool hasTokenAdminRole = accessManager.hasRole(TOKEN_ADMIN_ROLE, config.superAdmin);

        console.log("SuperAdmin has DEFAULT_ADMIN_ROLE:", hasDefaultAdminRole);
        console.log("SuperAdmin has ADMIN_ROLE:", hasAdminRole);
        console.log("SuperAdmin has TOKEN_ADMIN_ROLE:", hasTokenAdminRole);

        // Stop broadcasting
        vm.stopBroadcast();

        return accessManager;
    }
}
