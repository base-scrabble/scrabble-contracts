// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title AccessManager
/// @notice Centralized role, KYC, blacklist, and permission management for BaseScrabble game ecosystem
/// @dev Inherit OpenZeppelin AccessControl and Pausable for robust access and emergency controls
contract AccessManager is AccessControl, Pausable, ReentrancyGuard {
    /// @notice Role identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REALTOR_ROLE = keccak256("REALTOR_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
    bytes32 public constant TENANT_ROLE = keccak256("TENANT_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    /// @notice Role for managing tokens
    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");

    /// @notice Mapping to track KYC verification status
    mapping(address => bool) public isKYCVerified;

    /// @notice Mapping to track blacklisted addresses
    mapping(address => bool) public isBlacklisted;

    /// @notice Mapping to track whitelisted IP hashes (off-chain verification)
    mapping(bytes32 => bool) public isWhitelistedIP;

    /// @notice Struct for time-limited roles
    struct RoleExpiry {
        uint256 expiryTimestamp;
        bool enabled;
    }

    /// @notice Mapping for time-limited role expirations: user => role => expiry data
    mapping(address => mapping(bytes32 => RoleExpiry)) public roleExpiries;

    /// @notice Mapping for property-specific permissions: propertyId => user => allowed
    mapping(uint256 => mapping(address => bool)) public propertyPermissions;

    /// @notice Deploys AccessManager and assigns superAdmin as DEFAULT_ADMIN_ROLE and ADMIN_ROLE
    /// @param superAdmin The address to be granted top-level admin rights
    constructor(address superAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, superAdmin); // Give superAdmin full admin rights
        _grantRole(ADMIN_ROLE, superAdmin); // Also grant explicit ADMIN_ROLE
        _grantRole(TOKEN_ADMIN_ROLE, superAdmin);
    }

    // --- MODIFIERS ---

    /// @notice Restricts access to users with either admin or auditor role
    modifier onlyAdminOrAuditor() virtual {
        bytes32[] memory roles = new bytes32[](2); // Properly declare the array
        roles[0] = DEFAULT_ADMIN_ROLE;
        roles[1] = AUDITOR_ROLE;

        require(hasAnyRole(msg.sender, roles), "Not admin or auditor");
        _;
    }

    /// @notice Restricts function to non-paused state
    // This modifier overrides the one from Pausable.sol
    modifier whenNotPaused() override {
        require(!paused(), "System paused");
        _;
    }

    /// @notice Restricts function to non-blacklisted addresses
    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "Blacklisted");
        _;
    }

    /// @notice Restricts function to whitelisted IPs (off-chain hash)
    /// @param ipHash The hash of the user's IP address
    modifier onlyWhitelistedIP(bytes32 ipHash) {
        require(isWhitelistedIP[ipHash], "IP not allowed");
        _;
    }

    /// @notice Restricts function to KYC-verified addresses
    modifier onlyKYCVerified() {
        require(isKYCVerified[msg.sender], "Not KYC verified");
        _;
    }

    /// @notice Restricts function to users with a valid (non-expired) role
    /// @param role The role to check
    modifier checkRoleTime(bytes32 role) {
        RoleExpiry memory data = roleExpiries[msg.sender][role];
        if (data.enabled) {
            require(block.timestamp <= data.expiryTimestamp, "Role expired");
        }
        _;
    }

    // --- ADMIN & AUDITOR FUNCTIONS ---

    /// @notice Checks if an account has any one of the given roles
    /// @param account The address to check
    /// @param roles An array of role identifiers
    /// @return True if the account has at least one role
    function hasAnyRole(address account, bytes32[] memory roles) public view returns (bool) {
        for (uint256 i = 0; i < roles.length; i++) {
            if (hasRole(roles[i], account)) {
                return true;
            }
        }
        return false;
    }

    /// @notice Set KYC verification status for a user (auditor only)
    /// @param user The address to update
    /// @param status True if KYC verified, false otherwise
    function setKYC(address user, bool status) external onlyRole(AUDITOR_ROLE) {
        isKYCVerified[user] = status;
    }

    /// @notice Blacklist or unblacklist a user (admin only)
    /// @param user The address to update
    /// @param status True to blacklist, false to remove from blacklist
    function blacklist(address user, bool status) external onlyRole(ADMIN_ROLE) {
        isBlacklisted[user] = status;
    }

    /// @notice Whitelist or remove an IP hash (admin only)
    /// @param ipHash The hash of the IP address
    /// @param status True to whitelist, false to remove
    function whitelistIP(bytes32 ipHash, bool status) external onlyRole(ADMIN_ROLE) {
        isWhitelistedIP[ipHash] = status;
    }

    /// @notice Grant a time-limited role to a user (admin only)
    /// @param user The address to grant the role to
    /// @param role The role identifier
    /// @param duration Duration in seconds for which the role is valid
    function setTimeLimitedRole(address user, bytes32 role, uint256 duration) external onlyRole(ADMIN_ROLE) {
        roleExpiries[user][role] = RoleExpiry({expiryTimestamp: block.timestamp + duration, enabled: true});
        grantRole(role, user);
    }

    /// @notice Grant property-specific permission to a user (realtor only)
    /// @param propertyId The property identifier
    /// @param user The address to grant permission to
    function grantPropertyPermission(uint256 propertyId, address user) external onlyRole(REALTOR_ROLE) {
        propertyPermissions[propertyId][user] = true;
    }

    /// @notice Revoke property-specific permission from a user (realtor only)
    /// @param propertyId The property identifier
    /// @param user The address to revoke permission from
    function revokePropertyPermission(uint256 propertyId, address user) external onlyRole(REALTOR_ROLE) {
        propertyPermissions[propertyId][user] = false;
    }

    /// @notice Pause the contract (admin only)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract (admin only)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // --- VIEW HELPERS ---

    /// @notice Check if a user has access to a property
    /// @param propertyId The property identifier
    /// @param user The address to check
    /// @return True if the user has access, false otherwise
    function hasAccessToProperty(uint256 propertyId, address user) external view returns (bool) {
        return propertyPermissions[propertyId][user];
    }

    /// @notice Check if a user's role is still valid (not expired)
    /// @param user The address to check
    /// @param role The role identifier
    /// @return True if the role is valid, false otherwise
    function roleValid(address user, bytes32 role) public view returns (bool) {
        RoleExpiry memory data = roleExpiries[user][role];
        if (!data.enabled) return true;
        return block.timestamp <= data.expiryTimestamp;
    }

    /// @notice Check if a user has a role, is KYC verified, not blacklisted, and role is valid
    /// @param user The address to check
    /// @param role The role identifier
    /// @return True if all conditions are met, false otherwise
    function hasRoleAndKYC(address user, bytes32 role) external view returns (bool) {
        return hasRole(role, user) && isKYCVerified[user] && !isBlacklisted[user] && roleValid(user, role);
    }
}
