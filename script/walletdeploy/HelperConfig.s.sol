// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;    

import {Wallet} from "../../src/wallet/Wallet.sol";
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../../test/mocks/MocksV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script{
    struct NetworkConfig{
        address priceFeed;
        address superAdmin;
        address usdt;
        address backendSigner; 
        address usdc;
    }

    NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid == 84532){
            activeNetworkConfig = getBaseSepoliaEthConfig();
        }
        else if(block.chainid == 1) {
            activeNetworkConfig = getMainNetEthConfig();
        }
        else{
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getBaseSepoliaEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory baseSepoliaConfig = NetworkConfig({
        priceFeed: 0x3ec8593F930EA45ea58c968260e6e9FF53FC934f,
        superAdmin: address(0x1),
        usdt: address(0x4),
        backendSigner: address(0x3),
        usdc:address(0x5)
        });
        return baseSepoliaConfig;
    }
    function getMainNetEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory mainNetConfig = NetworkConfig({
        priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
        superAdmin: address(0x1),
        usdt: address(0xdAC17F958D2ee523a2206206994597C13D831ec7),
        backendSigner: address(0x3),
        usdc:address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
        });
        return mainNetConfig;  
    }

    function getAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        address mockPriceFeed = address(new MockV3Aggregator(8, 2000e8));
        address usdt = address(new ERC20Mock());
        address usdc = address(new ERC20Mock());
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: mockPriceFeed,
            superAdmin: msg.sender,
            usdt: usdt,
            backendSigner: msg.sender,
            usdc: usdc
        });
        return anvilConfig;
    }         

   
}