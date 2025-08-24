// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Wallet} from "../src/wallet/Wallet.sol";
import {Scrabble} from "../src/scrabble-game/Scrabble.sol";
import {Script} from "forge-std/Script.sol";

contract DeployScrabble is Script {
    function run() external returns (Scrabble, Wallet) {
        Wallet wallet;
        Scrabble scrabble;

        vm.startBroadcast();
        wallet = new Wallet( /*address priceFeed*/ );
        scrabble = new Scrabble( /*address priceFeed,*/ address(wallet));
        vm.stopBroadcast();

        return (scrabble, wallet);
    }
}
