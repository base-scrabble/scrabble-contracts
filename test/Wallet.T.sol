// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/wallet/Wallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title WalletUnitTest
/// @notice Unit tests for the Wallet contract
/// @dev Tests individual functions like deposit, withdraw, and authorization
contract WalletUnitTest is Test {
    Wallet wallet;
    address superAdmin = address(0x1);
    address user = address(0x2);
    address priceFeed = address(0x3);
    address usdt = address(0x4);
    address usdc = address(0x5);
    address backendSigner = address(0x6);

    /// @notice Sets up the test environment with mock contracts and Wallet deployment
    /// @dev Configures mock price feed and token contracts, deploys Wallet
    function setUp() public {
        vm.etch(priceFeed, bytes("mock"));
        vm.mockCall(priceFeed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(0, 2000e8, 0, 0, 0));
        vm.etch(usdt, bytes("mock"));
        vm.etch(usdc, bytes("mock"));
        wallet = new Wallet(priceFeed, superAdmin, usdt, backendSigner, usdc);
        console.log("Wallet deployed at", address(wallet));
    }

    /// @notice Tests depositing ETH into the Wallet
    /// @dev Verifies balance update after ETH deposit
    function test_DepositETH() public {
        bytes memory sig = signAuth(user, backendSigner);
        vm.deal(user, 1 ether);
        vm.prank(user);
        console.log("Depositing 1 ETH for user:", user);
        wallet.depositETH{value: 1 ether}(sig);
        uint256 balance = wallet.getBalance(user, address(0));
        console.log("User ETH balance after deposit:", balance);
        assertEq(balance, 1 ether, "ETH balance should be 1 ether");
    }

    /// @notice Tests withdrawing ETH from the Wallet
    /// @dev Deposits ETH, withdraws half, and verifies balance
    function test_WithdrawETH() public {
        bytes memory sig = signAuth(user, backendSigner);
        vm.deal(user, 1 ether);
        vm.prank(user);
        console.log("Depositing 1 ETH for user:", user);
        wallet.depositETH{value: 1 ether}(sig);
        vm.prank(user);
        console.log("Withdrawing 0.5 ETH for user:", user);
        wallet.withdrawETH(0.5 ether, sig);
        uint256 balance = wallet.getBalance(user, address(0));
        console.log("User ETH balance after withdrawal:", balance);
        assertEq(balance, 0.5 ether, "ETH balance should be 0.5 ether");
    }

    /// @notice Tests depositing USDT tokens into the Wallet
    /// @dev Mocks token transfer and verifies balance update
    function test_DepositToken() public {
        bytes memory sig = signAuth(user, backendSigner);
        vm.mockCall(usdt, abi.encodeWithSelector(IERC20.transferFrom.selector), abi.encode(true));
        vm.prank(user);
        console.log("Depositing 100e6 USDT for user:", user);
        wallet.depositToken(usdt, 100e6, sig);
        uint256 balance = wallet.getBalance(user, usdt);
        console.log("User USDT balance after deposit:", balance);
        assertEq(balance, 100e6, "USDT balance should be 100e6");
    }

    /// @notice Tests setting an authorized caller
    /// @dev Verifies authorization status after setting
    function test_SetAuthorizedCaller() public {
        address caller = address(0x7);
        vm.prank(superAdmin);
        console.log("Setting authorized caller:", caller);
        wallet.setAuthorizedCaller(caller, true);
        bool isAuthorized = wallet.isAuthorizedCaller(caller);
        console.log("Caller authorization status:", isAuthorized);
        assertTrue(isAuthorized, "Caller should be authorized");
    }

    /// @notice Generates EIP-712 signature for authentication
    /// @param player Address of the player to sign for
    /// @param signer Address of the backend signer
    /// @return Signature bytes for authentication
    function signAuth(address player, address signer) internal returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(keccak256("Auth(address player)"), player));
        bytes32 digest = wallet._hashTypedDataV4(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
        console.log("Generated signature for player:", player);
        return abi.encodePacked(r, s, v);
    }
}