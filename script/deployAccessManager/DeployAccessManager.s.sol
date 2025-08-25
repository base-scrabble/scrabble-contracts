// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessManager} from "../../src/access/AccessManager.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployAccessManager is Script {

    AccessManager accessManager;
    function run() external returns (AccessManager) {
        HelperConfig helperConfig = new HelperConfig();
        (address superAdmin)= helperConfig.activeNetworkConfig();
         


        vm.startBroadcast();
        accessManager = new AccessManager(superAdmin);
        vm.stopBroadcast();

        return (accessManager);
    }
}