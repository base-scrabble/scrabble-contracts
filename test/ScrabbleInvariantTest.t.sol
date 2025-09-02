// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/scrabble-game/Scrabble.sol";
import "../src/wallet/Wallet.sol";

/// @title ScrabbleInvariantTest
/// @notice Invariant tests for Scrabble and Wallet contracts
/// @dev Verifies key properties like non-negative balances and game settlement rules
contract ScrabbleInvariantTest is Test {
    Scrabble scrabble;
    Wallet wallet;
    address superAdmin = address(0x1);
    address submitter = address(0x2);
    address backendSigner = address(0x3);
    address player1 = address(0x4);
    address usdt = address(0x5);
    address usdc = address(0x6);
    address priceFeed = address(0x7);

    /// @notice Sets up the test environment with mock contracts and initial configurations
    /// @dev Deploys Wallet and Scrabble contracts, sets up mocks for price feed and tokens
    function setUp() public {
        vm.etch(priceFeed, bytes("mock"));
        vm.mockCall(
            priceFeed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, 2000e8, 0, 0, 0)
        );
        vm.etch(usdt, bytes("mock"));
        vm.etch(usdc, bytes("mock"));
        wallet = new Wallet(priceFeed, superAdmin, usdt, backendSigner, usdc);
        scrabble = new Scrabble(address(wallet), superAdmin, submitter, backendSigner, usdt, usdc, priceFeed);
        vm.prank(superAdmin);
        wallet.setAuthorizedCaller(address(scrabble), true);
        console.log("Test environment set up with Wallet at", address(wallet), "and Scrabble at", address(scrabble));
    }

    /// @notice Ensures all player balances are non-negative
    /// @dev Checks ETH, USDT, and USDC balances for player1
    function invariant_BalancesNonNegative() public {
        uint256 ethBalance = wallet.getBalance(player1, address(0));
        uint256 usdtBalance = wallet.getBalance(player1, usdt);
        uint256 usdcBalance = wallet.getBalance(player1, usdc);
        console.log("Checking balances for player", player1);

        // console.log("ETH balance:", ethBalance, "USDT balance:", usdtBalance, "USDC balance:", usdcBalance);

        console.log("ETH balance:");
        console.log(ethBalance);
        console.log("USDT balance:");
        console.log(usdtBalance);
        console.log("USDC balance:");
        console.log(usdcBalance);

        assertGe(ethBalance, 0, "ETH balance should be non-negative");
        assertGe(usdtBalance, 0, "USDT balance should be non-negative");
        assertGe(usdcBalance, 0, "USDC balance should be non-negative");
    }

    /// @notice Ensures games with fewer than 2 players remain locked
    /// @dev Verifies that games with insufficient players cannot be settled prematurely
    function invariant_GameNotSettledPrematurely() public {
        uint256 gameId = scrabble.GameId();
        console.log("Checking game ID", gameId);
        if (gameId > 0) {
            Scrabble.Game memory game = scrabble.getGame(gameId);
            console.log("Game players count:", game.players.length, "Funds locked:", game.fundsLocked);
            if (game.players.length < 2) {
                assertTrue(game.fundsLocked, "Game should remain locked with fewer than 2 players");
            }
        } else {
            console.log("No games created yet");
        }
    }
}
