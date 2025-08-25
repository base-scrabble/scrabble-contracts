// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Scrabble} from "../../src/scrabble-game/Scrabble.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployScrabble is Script {
    function run() external returns (Scrabble) {
        Scrabble scrabble;
        HelperConfig helperConfig = new HelperConfig();

        // ✅ Correct way to fetch the struct
       HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();


        vm.startBroadcast();

        scrabble = new Scrabble(
            config.wallet,
            config._superAdmin,
            config.submitter,
            config.backendSigner,
            config.usdt,
            config.usdc,
            config.ethUsdPriceFeed
        );

        vm.stopBroadcast();

        return scrabble;
    }
}
