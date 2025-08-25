// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/scrabble-game/Scrabble.sol";
import "../src/wallet/Wallet.sol";

/// @title ScrabbleIntegrationTest
/// @notice Integration tests for interactions between Scrabble and Wallet contracts
/// @dev Tests the full game lifecycle including creation, joining, and settlement
contract ScrabbleIntegrationTest is Test {
    Scrabble scrabble;
    Wallet wallet;
    address superAdmin = address(0x1);
    address submitter = address(0x2);
    address backendSigner = address(0x3);
    address player1 = address(0x4);
    address player2 = address(0x5);
    address usdt = address(0x6);
    address usdc = address(0x7);
    address priceFeed = address(0x8);

    /// @notice Sets up the test environment with mock contracts and initial configurations
    /// @dev Deploys Wallet and Scrabble contracts, configures mocks for price feed and tokens
    function setUp() public {
        vm.etch(priceFeed, bytes("mock"));
        vm.mockCall(priceFeed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(0, 2000e8, 0, 0, 0));
        vm.etch(usdt, bytes("mock"));
        vm.etch(usdc, bytes("mock"));
        wallet = new Wallet(priceFeed, superAdmin, usdt, backendSigner, usdc);
        scrabble = new Scrabble(address(wallet), superAdmin, submitter, backendSigner, usdt, usdc, priceFeed);
        console.log("Test environment set up with Wallet at", address(wallet), "and Scrabble at", address(scrabble));
    }

    /// @notice Tests the complete game lifecycle: create, join, and settle a game
    /// @dev Verifies correct balance updates after a game is settled with a winner
    function test_CreateJoinSettleGame() public {
        bytes memory sig1 = signAuth(player1, backendSigner);
        bytes memory sig2 = signAuth(player2, backendSigner);
        console.log("Authorizing Scrabble contract as caller for Wallet");
        vm.prank(superAdmin);
        wallet.setAuthorizedCaller(address(scrabble), true);
        console.log("Depositing 1 ETH for player1:", player1);
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        wallet.depositETH{value: 1 ether}(sig1);
        console.log("Depositing 1 ETH for player2:", player2);
        vm.deal(player2, 1 ether);
        vm.prank(player2);
        wallet.depositETH{value: 1 ether}(sig2);
        console.log("Creating game with player1:", player1);
        vm.prank(player1);
        uint256 gameId = scrabble.createGame(1e6, address(0), sig1);
        console.log("Game created with ID:", gameId);
        console.log("Player2 joining game ID:", gameId);
        vm.prank(player2);
        scrabble.joinGame(gameId, 1e6, sig2);
        uint32[] memory scores = new uint32[](2);
        scores[0] = 100;
        scores[1] = 50;
        console.log("Submitting result for game ID:", gameId, "with winner:", player1);
        vm.prank(submitter);
        scrabble.submitResult(gameId, player1, bytes32(0), scores, 0);
        console.log("Verifying player1 balance:", wallet.getBalance(player1, address(0)));
        console.log("Verifying player2 balance:", wallet.getBalance(player2, address(0)));
        assertEq(wallet.getBalance(player1, address(0)), 1e6 * 2, "Player1 should receive total pot");
        assertEq(wallet.getBalance(player2, address(0)), 0, "Player2 should have zero balance");
    }

    /// @notice Generates EIP-712 signature for authentication
    /// @param player Address of the player to sign for
    /// @param signer Address of the backend signer
    /// @return Signature bytes for authentication
    function signAuth(address player, address signer) internal returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(keccak256("Auth(address player)"), player));
        bytes32 digest = scrabble._hashTypedDataV4(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
        console.log("Generated signature for player:", player);
        return abi.encodePacked(r, s, v);
    }
}