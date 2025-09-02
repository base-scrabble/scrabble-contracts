// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Scrabble} from "../../src/scrabble-game/Scrabble.sol";
import {Script} from "forge-std/Script.sol";
import {Wallet} from "../../src/wallet/Wallet.sol";
import {DeployWallet} from "../walletdeploy/DeployWallet.s.sol";
import {MockV3Aggregator} from "../../test/mocks/MocksV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    Wallet wallet;

    DeployWallet deployWallet = new DeployWallet();

    struct NetworkConfig {
        address wallet;
        address _superAdmin;
        address submitter;
        address backendSigner;
        address usdt;
        address usdc;
        address ethUsdPriceFeed;
    }

    NetworkConfig internal activeNetworkConfig;

    constructor() {
        if (block.chainid == 84532) {
            activeNetworkConfig = getBaseSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainNetEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getBaseSepoliaEthConfig() public returns (NetworkConfig memory) {
        NetworkConfig memory baseSepoliaConfig = NetworkConfig({
            wallet: address(deployWallet.run()),
            _superAdmin: address(0x1),
            submitter: address(0x2),
            backendSigner: address(0x3),
            usdt: address(0x4),
            usdc: address(0x5),
            ethUsdPriceFeed: 0x3ec8593F930EA45ea58c968260e6e9FF53FC934f
        });
        return baseSepoliaConfig;
    }

    function getMainNetEthConfig() public returns (NetworkConfig memory) {
        NetworkConfig memory mainNetConfig = NetworkConfig({
            wallet: address(deployWallet.run()),
            _superAdmin: address(0x1),
            submitter: address(0x2),
            backendSigner: address(0x3),
            usdt: address(0xdAC17F958D2ee523a2206206994597C13D831ec7),
            usdc: address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            ethUsdPriceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainNetConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wallet != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();

        address usdt = address(new ERC20Mock());
        address usdc = address(new ERC20Mock());
        address mockPriceFeed = address(new MockV3Aggregator(8, 2000e8));
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            wallet: address(deployWallet.run()),
            _superAdmin: msg.sender,
            submitter: address(0x2),
            backendSigner: msg.sender,
            usdt: usdt,
            usdc: usdc,
            ethUsdPriceFeed: mockPriceFeed
        });
        return anvilConfig;
    }

    function getActiveNetworkConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
