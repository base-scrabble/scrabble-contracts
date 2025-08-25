// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AccessManager} from "../../src/access/AccessManager.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script{
    struct NetworkConfig{
        address superAdmin;
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
        superAdmin: address(0x1)
        });
        return baseSepoliaConfig;
    }
    function getMainNetEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory mainNetConfig = NetworkConfig({
        superAdmin: address(0x1)
        });
        return mainNetConfig;   
    }

    function getAnvilEthConfig() public view returns(NetworkConfig memory){
        if(activeNetworkConfig.superAdmin != address(0)){
            return activeNetworkConfig;
        }
        NetworkConfig memory anvilConfig = NetworkConfig({
        superAdmin: msg.sender
        });
        return anvilConfig;
    }
}