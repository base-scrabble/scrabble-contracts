// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/scrabble-game/Scrabble.sol";
import "../src/wallet/Wallet.sol";

/// @title ScrabbleUnitTest
/// @notice Unit tests for the Scrabble contract
/// @dev Tests individual functions like game creation, joining, and result submission
contract ScrabbleUnitTest is Test {
    Scrabble scrabble;
    Wallet wallet;
    address superAdmin = address(0x1);
    address submitter = address(0x2);
    address backendSigner = address(0x3);
    address player1 = address(0x4);
    address usdt = address(0x5);
    address usdc = address(0x6);
    address priceFeed = address(0x7);

    /// @notice Sets up the test environment with mock contracts and Scrabble/Wallet deployment
    /// @dev Configures mock price feed and token contracts, deploys Wallet and Scrabble
    function setUp() public {
        vm.etch(priceFeed, bytes("mock"));
        vm.mockCall(priceFeed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(0, 2000e8, 0, 0, 0));
        vm.etch(usdt, bytes("mock"));
        vm.etch(usdc, bytes("mock"));
        wallet = new Wallet(priceFeed, superAdmin, usdt, backendSigner, usdc);
        scrabble = new Scrabble(address(wallet), superAdmin, submitter, backendSigner, usdt, usdc, priceFeed);
        console.log("Scrabble deployed at", address(scrabble), "and Wallet at", address(wallet));
    }

    /// @notice Tests creating a new game
    /// @dev Verifies that the game is created and the creator is set as the first player
    function test_CreateGame() public {
        bytes memory sig = signAuth(player1, backendSigner);
        console.log("Authorizing Scrabble as caller for Wallet by superAdmin:", superAdmin);
        vm.prank(superAdmin);
        wallet.setAuthorizedCaller(address(scrabble), true);
        console.log("Depositing 1 ETH for player1:", player1);
        vm.prank(player1);
        vm.deal(player1, 1 ether);
        wallet.depositETH{value: 1 ether}(sig);
        console.log("Creating game with player1:", player1, "and stake 1e6");
        vm.prank(player1);
        uint256 gameId = scrabble.createGame(1e6, address(0), sig);
        address firstPlayer = scrabble.getGame(gameId).players[0];
        console.log("Game ID:", gameId, "First player:", firstPlayer);
        assertEq(firstPlayer, player1, "First player should be player1");
    }

    /// @notice Tests joining an existing game
    /// @dev Verifies that a second player can join and is added to the game
    function test_JoinGame() public {
        bytes memory sig1 = signAuth(player1, backendSigner);
        bytes memory sig2 = signAuth(address(0x8), backendSigner);
        console.log("Authorizing Scrabble as caller for Wallet by superAdmin:", superAdmin);
        vm.prank(superAdmin);
        wallet.setAuthorizedCaller(address(scrabble), true);
        console.log("Depositing 1 ETH for player1:", player1);
        vm.prank(player1);
        vm.deal(player1, 1 ether);
        wallet.depositETH{value: 1 ether}(sig1);
        console.log("Creating game with player1:", player1);
        vm.prank(player1);
        uint256 gameId = scrabble.createGame(1e6, address(0), sig1);
        console.log("Depositing 1 ETH for player2:", address(0x8));
        vm.prank(address(0x8));
        vm.deal(address(0x8), 1 ether);
        wallet.depositETH{value: 1 ether}(sig2);
        console.log("Player2 joining game ID:", gameId);
        vm.prank(address(0x8));
        scrabble.joinGame(gameId, 1e6, sig2);
        address secondPlayer = scrabble.getGame(gameId).players[1];
        console.log("Second player in game ID", gameId, ":", secondPlayer);
        assertEq(secondPlayer, address(0x8), "Second player should be address(0x8)");
    }

    /// @notice Tests submitting a game result
    /// @dev Verifies that the result is submitted and the winner is set correctly
    function test_SubmitResult() public {
        bytes memory sig = signAuth(player1, backendSigner);
        console.log("Authorizing Scrabble as caller for Wallet by superAdmin:", superAdmin);
        vm.prank(superAdmin);
        wallet.setAuthorizedCaller(address(scrabble), true);
        console.log("Depositing 1 ETH for player1:", player1);
        vm.prank(player1);
        vm.deal(player1, 1 ether);
        wallet.depositETH{value: 1 ether}(sig);
        console.log("Creating game with player1:", player1);
        vm.prank(player1);
        uint256 gameId = scrabble.createGame(1e6, address(0), sig);
        uint32[] memory scores = new uint32[](1);
        scores[0] = 100;
        console.log("Submitting result for game ID:", gameId, "with winner:", player1);
        vm.prank(submitter);
        scrabble.submitResult(gameId, player1, bytes32(0), scores, 0);
        address winner = scrabble.getGame(gameId).winner;
        console.log("Winner for game ID", gameId, ":", winner);
        assertEq(winner, player1, "Winner should be player1");
    }

    /// @notice Generates EIP-712 signature for authentication
    /// @param player Address of the player to sign for
    /// @param signer Address of the backend signer
    /// @return Signature bytes for authentication
    function signAuth(address player, address signer) internal returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(keccak256("Auth(address player)"), player));
        bytes32 digest = scrabble.getDigest(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
        console.log("Generated signature for player:", player);
        return abi.encodePacked(r, s, v);
    }
}