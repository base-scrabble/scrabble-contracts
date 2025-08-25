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
 * @notice Simple deposit/withdraw wallet with game interaction helpers.
 * @dev This contract stores user balances and exposes functions for games to deduct stakes
 *      and credit winnings. Only authorized callers (games / controllers) can call those functions.
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
    // mapping(address => uint256) private s_balances;
    // balances[user][token] -> balance
    mapping(address => mapping(address => uint256)) private s_balances;
    uint256 private constant MINIMUM_DEPOSIT = 1e8;

    mapping(address => bool) private s_authorizedCallers; // games / controllers allowed to call deduct/add
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

    /// @notice Deploy wallet with price feed address and admin.
    /// @param priceFeed Chainlink price feed address (for conversion)
    /// @param superAdmin Admin address allowed to authorize game callers
    constructor(address priceFeed, address superAdmin, address usdt, address backendSigner, address usdc) 
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
    /// @notice Authorize or revoke an external contract that can call deductFunds/addWinnings.
    /// @param caller The caller to authorize (game contract, controller)
    /// @param authorized True to authorize, false to revoke
    function setAuthorizedCaller(address caller, bool authorized) external  onlyRole(ADMIN_ROLE)  whenNotPaused {
        s_authorizedCallers[caller] = authorized;
        emit CallerAuthorizationChanged(caller, authorized);
    }

    // ------------------------
    // Basic wallet ops
    // ------------------------

    // -------- ETH --------
    function depositETH(bytes calldata backendSig) external payable nonReentrant whenNotPaused notBlacklisted onlyAuthenticated(backendSig) {
        if (msg.value.getConversionRate(i_priceFeed) < MINIMUM_DEPOSIT) {
            revert Wallet__InsufficientFundsToDeposit();
        }
        s_balances[msg.sender][address(0)] += msg.value;
        emit FundsDeposited(msg.sender, address(0), msg.value);
    }

    function withdrawETH(uint256 amount, bytes calldata backendSig) external nonReentrant whenNotPaused notBlacklisted onlyAuthenticated(backendSig){
        uint256 balance = s_balances[msg.sender][address(0)];
        if (amount > balance) revert Wallet__BalanceIsLessThanAmountToWithdraw();
        if (amount == 0) revert Wallet__AmountTooSmall();

        s_balances[msg.sender][address(0)] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert Wallet__TransferFailed();

        emit FundsWithdrawn(msg.sender, address(0), amount);
    }

    // -------- ERC20 (USDT/USDC) --------
    function depositToken(address token, uint256 amount, bytes calldata backendSig) external  whenNotPaused nonReentrant notBlacklisted onlyAuthenticated(backendSig) {
        if (!_isSupportedToken(token)) revert Wallet__UnsupportedToken();
        if (amount == 0) revert Wallet__AmountTooSmall();

        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) revert Wallet__TransferFailed();

        s_balances[msg.sender][token] += amount;
        emit FundsDeposited(msg.sender, token, amount);
    }

    function withdrawToken(address token, uint256 amount, bytes calldata backendSig) external  whenNotPaused nonReentrant notBlacklisted onlyAuthenticated(backendSig) {
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

    /// @notice Called by authorized game / controller to lock/deduct funds for a stake.
    /// @param user User whose balance to deduct
    /// @param amount Amount to deduct
    function deductFunds(address user, address token, uint256 amount)
        external
         whenNotPaused
        onlyAuthorizedCaller
        nonReentrant
        returns (bool)
    {
        if (!_isSupportedToken(token) && token != address(0)) revert Wallet__UnsupportedToken();
        if (amount > s_balances[user][token]) revert Wallet__InsufficientBalanceToStake();

        // Effects
        s_balances[user][token] -= amount;

        emit FundsTransferredToGame(user, token, amount);
        return true;
    }

    /// @notice Called by authorized game / controller to credit winnings to a user balance.
    /// @param user User to credit
    /// @param amount Amount to credit
    function addWinnings(address user, address token, uint256 amount) external  whenNotPaused onlyAuthorizedCaller nonReentrant {
        if (!_isSupportedToken(token) && token != address(0)) revert Wallet__UnsupportedToken();
        // Effects
        s_balances[user][token] += amount;
        emit FundsReceivedFromGame(user, token, amount);
    }

        // ------------------------
    // Internal helpers
    // ------------------------

    function _verifyBackendSignature(bytes calldata backendSig) internal view {
        bytes32 structHash = keccak256(abi.encode(_AUTH_TYPEHASH, msg.sender));
        bytes32 digest = _hashTypedDataV4(structHash);
        address recovered = ECDSA.recover(digest, backendSig);
        if (recovered != i_backendSigner) revert Wallet__NotAuthenticated();
    }

       function _isSupportedToken(address token) internal view returns (bool) {
        return (token == USDT || token == USDC);
    }


    // ------------------------
    // Getters
    // ------------------------

    /// @notice Get on-chain balance for a user
    function getBalance(address user, address token) external view returns (uint256) {
        return s_balances[user][token];
    }

    /// @notice Minimum deposit threshold (same as MINIMUM_DEPOSIT)
    function getMinimumDeposit() external pure returns (uint256) {
        return MINIMUM_DEPOSIT;
    }


    /// @notice Check if caller is authorized
    function isAuthorizedCaller(address caller) external view returns (bool) {
        return s_authorizedCallers[caller];
    }
}
