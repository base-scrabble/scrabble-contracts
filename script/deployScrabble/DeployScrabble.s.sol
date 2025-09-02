// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Scrabble} from "../../src/scrabble-game/Scrabble.sol";
import {ScrabbleConfig} from "./ScrabbleConfig.s.sol";
import {console} from "forge-std/console.sol";

contract DeployScrabble is Script {
    function run() external returns (Scrabble) {
        // Initialize configuration
        ScrabbleConfig scrabbleConfig = new ScrabbleConfig();
        ScrabbleConfig.NetworkConfig memory config = scrabbleConfig.getNetworkConfig();

        // Validate inputs
        require(config.superAdmin != address(0), "Invalid superAdmin address");
        require(config.wallet != address(0), "Invalid wallet address");
        require(config.submitter != address(0), "Invalid submitter address");
        require(config.backendSigner != address(0), "Invalid backendSigner address");
        require(config.usdt != address(0), "Invalid USDT address");
        require(config.usdc != address(0), "Invalid USDC address");
        require(config.ethUsdPriceFeed != address(0), "Invalid ethUsdPriceFeed address");

        console.log("Deploying Scrabble with:");
        console.log("  superAdmin:", config.superAdmin);
        console.log("  wallet:", config.wallet);
        console.log("  submitter:", config.submitter);
        console.log("  backendSigner:", config.backendSigner);
        console.log("  USDT:", config.usdt);
        console.log("  USDC:", config.usdc);
        console.log("  ethUsdPriceFeed:", config.ethUsdPriceFeed);

        // Start broadcasting
        vm.startBroadcast();

        // Deploy Scrabble
        Scrabble scrabble = new Scrabble(
            config.wallet,
            config.superAdmin,
            config.submitter,
            config.backendSigner,
            config.usdt,
            config.usdc,
            config.ethUsdPriceFeed
        );

        console.log("Scrabble admin matches superAdmin:", scrabble.hasRole(keccak256("ADMIN_ROLE"), config.superAdmin));

        // Stop broadcasting
        vm.stopBroadcast();

        return scrabble;
    }
}
