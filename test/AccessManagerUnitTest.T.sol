// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/access/AccessManager.sol";

/// @title AccessManagerUnitTest
/// @notice Unit tests for the AccessManager contract
/// @dev Tests individual functions like role granting, KYC, blacklist, whitelist, and pausing
contract AccessManagerUnitTest is Test {
    AccessManager accessManager;
    address superAdmin;
    address user ;
    bytes32 ipHash = keccak256("192.168.1.1");

    /// @notice Sets up the test environment by deploying the AccessManager contract
    /// @dev Configures the contract with superAdmin as the initial admin
    function setUp() public {
        superAdmin = makeAddr("superAdmin");
        user = makeAddr("user");
        accessManager = new AccessManager(superAdmin);
        // accessManager.grantRole(accessManager.DEFAULT_ADMIN_ROLE(), superAdmin);
        // console.log("AccessManager deployed at");
        // console.logAddress(address(accessManager));
        // console.log("with superAdmin");
        // console.logAddress(superAdmin);
    }


    /// @notice Tests granting the ADMIN_ROLE to a user
    /// @dev Verifies that the user receives the admin role
function test_GrantAdminRole() public {
    // Check that superAdmin actually has DEFAULT_ADMIN_ROLE
    bool isAdmin = accessManager.hasRole(accessManager.DEFAULT_ADMIN_ROLE(), superAdmin);
    assertTrue(isAdmin, "superAdmin should have DEFAULT_ADMIN_ROLE");

    // Act as superAdmin
    vm.startPrank(superAdmin);

    console.log("Granting ADMIN_ROLE to user:");
    console.log(address(user));

    // Grant role to user
    accessManager.grantRole(accessManager.ADMIN_ROLE(), user);

    vm.stopPrank();

    // Verify user now has ADMIN_ROLE
    bool hasRole = accessManager.hasRole(accessManager.ADMIN_ROLE(), user);
    console.log("User has ADMIN_ROLE:");
    console.logBool(hasRole);

    assertTrue(hasRole, "User should have ADMIN_ROLE");
}



    // /// @notice Tests granting the ADMIN_ROLE to a user
    // /// @dev Verifies that the user receives the admin role
    // function test_GrantAdminRole() public {
    //     vm.prank(superAdmin);
    //     console.log("Granting ADMIN_ROLE to user:");
    //     console.logAddress(user);
    //     // accessManager.grantRole(accessManager.ADMIN_ROLE(), user);
    //     // bool hasRole = accessManager.hasRole(accessManager.ADMIN_ROLE(), user);
    //     // console.log("User has ADMIN_ROLE:");
    //     // console.logBool(hasRole);
    //     // assertTrue(hasRole, "User should have ADMIN_ROLE");
    // }


    // /// @notice Tests setting KYC verification for a user
    // /// @dev Grants AUDITOR_ROLE to a user, then sets KYC status for another address
    // function test_SetKYC() public {
    //     vm.prank(superAdmin);
    //     console.log("Granting AUDITOR_ROLE to user:");
    //     console.logAddress(user);
    //     accessManager.grantRole(accessManager.AUDITOR_ROLE(), user);
    //     vm.prank(user);
    //     address target = address(0x3);
    //     console.log("Setting KYC for address:");
    //     console.logAddress(target);
    //     accessManager.setKYC(target, true);
    //     bool isVerified = accessManager.isKYCVerified(target);
    //     console.log("KYC status:");
    //     console.logBool(isVerified);
    //     assertTrue(isVerified, "Address should be KYC verified");
    // }

    /// @notice Tests blacklisting a user
    /// @dev Verifies that the user is added to the blacklist
    function test_Blacklist() public {
        vm.prank(superAdmin);
        console.log("Blacklisting user:");
        console.logAddress(user);
        accessManager.blacklist(user, true);
        bool isBlacklisted = accessManager.isBlacklisted(user);
        console.log("Blacklist status:");
        console.logBool(isBlacklisted);
        assertTrue(isBlacklisted, "User should be blacklisted");
    }

    // /// @notice Tests whitelisting an IP hash
    // /// @dev Verifies that the IP hash is added to the whitelist
    // function test_WhitelistIP() public {
    //     vm.prank(superAdmin);
    //     console.log("Whitelisting IP hash:");
    //     console.logBytes32(ipHash);
    //     accessManager.whitelistIP(ipHash, true);
    //     bool isWhitelisted = accessManager.isWhitelistedIP(ipHash);
    //     console.log("Whitelist status for IP hash:");
    //     console.logBool(isWhitelisted);
    //     assertTrue(isWhitelisted, "IP hash should be whitelisted");
    // }

    // /// @notice Tests setting a time-limited role for a user
    // /// @dev Grants a time-limited REALTOR_ROLE and verifies role and expiry
    // function test_SetTimeLimitedRole() public {
    //     vm.prank(superAdmin);
    //     console.log("Setting time-limited REALTOR_ROLE for user:");
    //     console.logAddress(user);
    //     accessManager.setTimeLimitedRole(user, accessManager.REALTOR_ROLE(), 1 days);
    //     bool hasRole = accessManager.hasRole(accessManager.REALTOR_ROLE(), user);
    //     uint256 expiry = accessManager.roleExpiries(user, accessManager.REALTOR_ROLE()).expiryTimestamp;
    //     console.log("User has REALTOR_ROLE:");
    //     console.logBool(hasRole);
    //     console.log("Expiry:");
    //     console.logUint(expiry);
    //     assertTrue(hasRole, "User should have REALTOR_ROLE");
    //     assertEq(expiry, block.timestamp + 1 days, "Role expiry should be 1 day from now");
    // }

    /// @notice Tests pausing the contract
    /// @dev Verifies that the contract is paused by the superAdmin
    function test_Pause() public {
        vm.prank(superAdmin);
        console.log("Pausing contract by superAdmin:");
        console.logAddress(superAdmin);
        accessManager.pause();
        bool isPaused = accessManager.paused();
        console.log("Contract paused status:");
        console.logBool(isPaused);
        assertTrue(isPaused, "Contract should be paused");
    }
}