// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import {Script} from "forge-std/Script.sol";
// import {MockERC20} from "../../src/MockERC20.sol";
// import {HelperConfig} from "../deployAccessManager/HelperConfig.s.sol";
// import {console} from "forge-std/console.sol";

// contract DeployMocks is Script {
//     function run() external returns (address, address) {
//         // Initialize configuration
//         HelperConfig helperConfig = new HelperConfig();
//         HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig();

//         vm.startBroadcast();

//         // Deploy Mock USDT
//         MockERC20 usdt = new MockERC20(config.usdtName, config.usdtSymbol, config.usdtSupply);
//         console.log("Mock USDT deployed to:", address(usdt));

//         // Deploy Mock USDC
//         MockERC20 usdc = new MockERC20(config.usdcName, config.usdcSymbol, config.usdcSupply);
//         console.log("Mock USDC deployed to:", address(usdc));

//         vm.stopBroadcast();
//         return (address(usdt), address(usdc));
//     }
// }
