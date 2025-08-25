// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PriceConverter} from "../libraries/PriceConverter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessManager} from "../access/AccessManager.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title Wallet
 * @author Adebaki Olujimi
 * @notice Secure multi-token wallet with game integration and EIP-712 authentication
 * @dev This contract stores user balances for ETH, USDT, and USDC, and exposes functions
 *      for games to deduct stakes and credit winnings. Only authorized callers can interact
 *      with game functions, and all user operations require backend authentication.
 */
contract Wallet is EIP712, AccessManager {
    using PriceConverter for uint256;

    /// ERRORS
    error Wallet__InsufficientDepositAmount();
    error Wallet__BalanceLessThanWithdraw();
    error Wallet__AmountTooSmall();
    error Wallet__TransferFailed();
    error Wallet__InsufficientBalanceToStake();
    error Wallet__NotAuthorized();
    error Wallet__InsufficientFundsToDeposit();
    error Wallet__UnsupportedToken();
    error Wallet__BalanceIsLessThanAmountToWithdraw();
    error Wallet__NotAuthenticated();

    /// STORAGE
    mapping(address => mapping(address => uint256)) private s_balances;
    uint256 private constant MINIMUM_DEPOSIT = 1e8;

    mapping(address => bool) private s_authorizedCallers;
    address private immutable i_admin;

    AggregatorV3Interface private immutable i_priceFeed;
    address public immutable USDT;
    address public immutable USDC;

    // EIP-712 authentication
    bytes32 private constant _AUTH_TYPEHASH = keccak256("Auth(address player)");
    address private immutable i_backendSigner;

    /// EVENTS
    event FundsDeposited(address indexed user, address indexed token, uint256 amount);
    event FundsWithdrawn(address indexed user, address indexed token, uint256 amount);
    event FundsTransferredToGame(address indexed user, address indexed token, uint256 amount);
    event FundsReceivedFromGame(address indexed user, address indexed token, uint256 amount);
    event CallerAuthorizationChanged(address indexed caller, bool authorized);

    /// MODIFIERS
    modifier onlyAdmin() {
        if (msg.sender != i_admin) revert Wallet__NotAuthorized();
        _;
    }

    modifier onlyAuthorizedCaller() {
        if (!s_authorizedCallers[msg.sender]) revert Wallet__NotAuthorized();
        _;
    }

    modifier onlyAuthenticated(bytes calldata backendSig) {
        _verifyBackendSignature(backendSig);
        _;
    }

    /**
     * @notice Deploy wallet with price feed, token addresses, and access control
     * @param priceFeed Chainlink price feed address for ETH/USD conversions
     * @param superAdmin Admin address with DEFAULT_ADMIN_ROLE and ADMIN_ROLE
     * @param usdt USDT token contract address
     * @param backendSigner EOA used for EIP-712 signature verification
     * @param usdc USDC token contract address
     */
    constructor(
        address priceFeed, 
        address superAdmin, 
        address usdt, 
        address backendSigner, 
        address usdc
    ) 
        EIP712("Wallet", "1") 
        AccessManager(superAdmin)
    {
        i_priceFeed = AggregatorV3Interface(priceFeed);
        i_admin = superAdmin;
        USDT = usdt;
        USDC = usdc;
        i_backendSigner = backendSigner;
    }

    // ------------------------
    // Admin: manage authorized callers (game contracts, controllers)
    // ------------------------
    
    /**
     * @notice Authorize or revoke an external contract that can call deductFunds/addWinnings
     * @param caller The contract address to authorize or revoke (game contract, controller)
     * @param authorized True to authorize, false to revoke permissions
     * @dev Only callable by addresses with ADMIN_ROLE when contract is not paused
     */
    function setAuthorizedCaller(address caller, bool authorized) external onlyRole(ADMIN_ROLE) whenNotPaused {
        s_authorizedCallers[caller] = authorized;
        emit CallerAuthorizationChanged(caller, authorized);
    }

    // ------------------------
    // Basic wallet operations
    // ------------------------

    // -------- ETH Operations --------
    
    /**
     * @notice Deposit ETH into the wallet
     * @param backendSig EIP-712 signature from backend authorizing the deposit
     * @dev Amount must meet MINIMUM_DEPOSIT requirement when converted to USD
     * @dev Requires backend authentication, non-reentrant, not paused, and not blacklisted
     */
    function depositETH(bytes calldata backendSig) external payable nonReentrant whenNotPaused notBlacklisted onlyAuthenticated(backendSig) {
        if (msg.value.getConversionRate(i_priceFeed) < MINIMUM_DEPOSIT) {
            revert Wallet__InsufficientFundsToDeposit();
        }
        s_balances[msg.sender][address(0)] += msg.value;
        emit FundsDeposited(msg.sender, address(0), msg.value);
    }

    /**
     * @notice Withdraw ETH from the wallet
     * @param amount Amount of ETH to withdraw in wei
     * @param backendSig EIP-712 signature from backend authorizing the withdrawal
     * @dev Requires sufficient balance, backend authentication, non-reentrant, not paused, and not blacklisted
     */
    function withdrawETH(uint256 amount, bytes calldata backendSig) external nonReentrant whenNotPaused notBlacklisted onlyAuthenticated(backendSig) {
        uint256 balance = s_balances[msg.sender][address(0)];
        if (amount > balance) revert Wallet__BalanceIsLessThanAmountToWithdraw();
        if (amount == 0) revert Wallet__AmountTooSmall();

        s_balances[msg.sender][address(0)] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert Wallet__TransferFailed();

        emit FundsWithdrawn(msg.sender, address(0), amount);
    }

    // -------- ERC20 Operations (USDT/USDC) --------
    
    /**
     * @notice Deposit ERC20 tokens (USDT or USDC) into the wallet
     * @param token Token contract address (must be USDT or USDC)
     * @param amount Amount of tokens to deposit (in token decimals)
     * @param backendSig EIP-712 signature from backend authorizing the deposit
     * @dev Requires token approval before calling, supports only USDT and USDC
     */
    function depositToken(address token, uint256 amount, bytes calldata backendSig) external whenNotPaused nonReentrant notBlacklisted onlyAuthenticated(backendSig) {
        if (!_isSupportedToken(token)) revert Wallet__UnsupportedToken();
        if (amount == 0) revert Wallet__AmountTooSmall();

        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) revert Wallet__TransferFailed();

        s_balances[msg.sender][token] += amount;
        emit FundsDeposited(msg.sender, token, amount);
    }

    /**
     * @notice Withdraw ERC20 tokens (USDT or USDC) from the wallet
     * @param token Token contract address (must be USDT or USDC)
     * @param amount Amount of tokens to withdraw (in token decimals)
     * @param backendSig EIP-712 signature from backend authorizing the withdrawal
     * @dev Requires sufficient balance of the specified token
     */
    function withdrawToken(address token, uint256 amount, bytes calldata backendSig) external whenNotPaused nonReentrant notBlacklisted onlyAuthenticated(backendSig) {
        if (!_isSupportedToken(token)) revert Wallet__UnsupportedToken();
        if (amount == 0) revert Wallet__AmountTooSmall();

        uint256 balance = s_balances[msg.sender][token];
        if (amount > balance) revert Wallet__BalanceIsLessThanAmountToWithdraw();

        s_balances[msg.sender][token] -= amount;

        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert Wallet__TransferFailed();

        emit FundsWithdrawn(msg.sender, token, amount);
    }

    // /// @notice Deposit ETH into the wallet (amount must meet MINIMUM_DEPOSIT in converted units).
    // function deposit() external payable nonReentrant {
    //     if (msg.value.getConversionRate(i_priceFeed) < MINIMUM_DEPOSIT) {
    //         revert Wallet__InsufficientDepositAmount();
    //     }

    //     // Effects
    //     s_balances[msg.sender] += msg.value;

    //     emit FundsDeposited(msg.sender, msg.value);
    // }

    // /// @notice Withdraw ETH from wallet. Follows CEI: update state then external call.
    // /// @param amount Amount in wei to withdraw
    // function withdraw(uint256 amount) external nonReentrant {
    //     uint256 balance = s_balances[msg.sender];
    //     if (amount == 0) revert Wallet__AmountTooSmall();
    //     if (amount > balance) revert Wallet__BalanceLessThanWithdraw();

    //     // Effects: update storage before external call (CEI)
    //     unchecked {
    //         s_balances[msg.sender] = balance - amount;
    //     }

    //     // Interaction
    //     (bool success, ) = payable(msg.sender).call{value: amount}("");
    //     if (!success) {
    //         // If transfer fails, revert and restore state is automatic because of revert.
    //         revert Wallet__TransferFailed();
    //     }

    //     emit FundsWithdrawn(msg.sender, amount);
    // }

    // ------------------------
    // Game interaction (must be authorized)
    // ------------------------

    /**
     * @notice Deduct funds from user balance for game staking (authorized callers only)
     * @param user User address whose balance to deduct
     * @param token Token address to deduct (address(0) for ETH, or USDT/USDC)
     * @param amount Amount to deduct from user balance
     * @return success Boolean indicating whether deduction was successful
     * @dev Only callable by authorized game contracts when not paused
     */
    function deductFunds(address user, address token, uint256 amount)
        external
        whenNotPaused
        onlyAuthorizedCaller
        nonReentrant
        returns (bool)
    {
        if (!_isSupportedToken(token) && token != address(0)) revert Wallet__UnsupportedToken();
        if (amount > s_balances[user][token]) revert Wallet__InsufficientBalanceToStake();

        s_balances[user][token] -= amount;
        emit FundsTransferredToGame(user, token, amount);
        return true;
    }

    /**
     * @notice Credit winnings to user balance from game settlements (authorized callers only)
     * @param user User address to credit winnings to
     * @param token Token address to credit (address(0) for ETH, or USDT/USDC)
     * @param amount Amount to credit to user balance
     * @dev Only callable by authorized game contracts when not paused
     */
    function addWinnings(address user, address token, uint256 amount) external whenNotPaused onlyAuthorizedCaller nonReentrant {
        if (!_isSupportedToken(token) && token != address(0)) revert Wallet__UnsupportedToken();
        s_balances[user][token] += amount;
        emit FundsReceivedFromGame(user, token, amount);
    }

    // ------------------------
    // Internal helpers
    // ------------------------

    /**
     * @notice Verify EIP-712 signature from backend
     * @param backendSig Signature to verify
     * @dev Internal function used for authentication modifier
     */
    function _verifyBackendSignature(bytes calldata backendSig) internal view {
        bytes32 structHash = keccak256(abi.encode(_AUTH_TYPEHASH, msg.sender));
        bytes32 digest = _hashTypedDataV4(structHash);
        address recovered = ECDSA.recover(digest, backendSig);
        if (recovered != i_backendSigner) revert Wallet__NotAuthenticated();
    }

    /**
     * @notice Check if token is supported (USDT or USDC)
     * @param token Token address to check
     * @return isSupported Boolean indicating whether token is supported
     * @dev Internal helper function
     */
    function _isSupportedToken(address token) internal view returns (bool) {
        return (token == USDT || token == USDC);
    }

    // ------------------------
    // Getters
    // ------------------------

    /**
     * @notice Get user balance for a specific token
     * @param user User address to query balance for
     * @param token Token address to check balance for (address(0) for ETH)
     * @return balance User's balance of the specified token
     */
    function getBalance(address user, address token) external view returns (uint256) {
        return s_balances[user][token];
    }

    /**
     * @notice Get minimum deposit amount
     * @return minimumDeposit Minimum deposit amount required
     */
    function getMinimumDeposit() external pure returns (uint256) {
        return MINIMUM_DEPOSIT;
    }

    /**
     * @notice Check if caller address is authorized for game interactions
     * @param caller Address to check authorization status for
     * @return isAuthorized Boolean indicating whether caller is authorized
     */
    function isAuthorizedCaller(address caller) external view returns (bool) {
        return s_authorizedCallers[caller];
    }
}