// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
// import "../src/scrabble-game/Scrabble.sol";
import {Scrabble} from "../src/scrabble-game/Scrabble.sol";
import {Wallet} from "../src/wallet/Wallet.sol";
// import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title ScrabbleHandler
/// @notice Handler contract for invariant and fuzz testing of Scrabble and Wallet contracts
/// @dev Simulates random sequences of deposits, game creation, joining, and result submission
contract ScrabbleHandler is Test {
    Scrabble scrabble;
    Wallet wallet;
    address superAdmin = address(0x1);
    address submitter = address(0x2);
    address backendSigner = address(0x3);
    address[] players = [address(0x4), address(0x5)];
    address usdt = address(0x6);
    address usdc = address(0x7);
    address priceFeed = address(0x8);

    /// @notice Initializes the handler with Scrabble and Wallet contract instances
    /// @param _scrabble Address of the Scrabble contract
    /// @param _wallet Address of the Wallet contract
    constructor(Scrabble _scrabble, Wallet _wallet) {
        scrabble = _scrabble;
        wallet = _wallet;
        vm.etch(priceFeed, bytes("mock"));
        vm.mockCall(priceFeed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(0, 2000e8, 0, 0, 0));
        vm.etch(usdt, bytes("mock"));
        vm.etch(usdc, bytes("mock"));
        vm.prank(superAdmin);
        wallet.setAuthorizedCaller(address(scrabble), true);
        console.log("Handler initialized with Scrabble at");
        console.logAddress(address(scrabble));
        console.log("and Wallet at");
        console.logAddress(address(wallet));
    }

    /// @notice Deposits ETH into the Wallet for a player
    /// @param amount Amount of ETH to deposit (bounded between 1e6 and 1 ether)
    /// @param playerIdx Index of the player in the players array
    function depositETH(uint256 amount, uint256 playerIdx) public {
        amount = bound(amount, 1e6, 1 ether);
        playerIdx = bound(playerIdx, 0, players.length - 1);
        address player = players[playerIdx];
        vm.deal(player, amount);
        bytes memory sig = signAuth(player);
        vm.prank(player);
        console.log("Depositing");
        console.logUint(amount);
        console.log("ETH for player");
        console.logAddress(player);
        wallet.depositETH{value: amount}(sig);
        console.log("Deposited");
        console.logUint(amount);
        console.log("ETH for player");
        console.logAddress(player);
        console.log("Balance:");
        console.logUint(wallet.getBalance(player, address(0)));
    }

    /// @notice Creates a new game in the Scrabble contract
    /// @param stake Amount to stake for the game (bounded between 1e6 and 1e18)
    /// @param playerIdx Index of the player in the players array
    function createGame(uint256 stake, uint256 playerIdx) public {
        stake = bound(stake, 1e6, 1e18);
        playerIdx = bound(playerIdx, 0, players.length - 1);
        address player = players[playerIdx];
        bytes memory sig = signAuth(player);
        vm.prank(player);
        console.log("Creating game with stake");
        console.logUint(stake);
        console.log("by player");
        console.logAddress(player);
        scrabble.createGame(stake, address(0), sig);
        console.log("Game created with ID");
        console.logUint(scrabble.GameId());
        console.log("by player");
        console.logAddress(player);
    }

    /// @notice Joins an existing game in the Scrabble contract
    /// @param gameId ID of the game to join
    /// @param stake Amount to stake (must match game stake)
    /// @param playerIdx Index of the player in the players array
    function joinGame(uint256 gameId, uint256 stake, uint256 playerIdx) public {
        gameId = bound(gameId, 1, scrabble.GameId());
        stake = bound(stake, 1e6, 1e18);
        playerIdx = bound(playerIdx, 0, players.length - 1);
        address player = players[playerIdx];
        bytes memory sig = signAuth(player);
        vm.prank(player);
        console.log("Player");
        console.logAddress(player);
        console.log("attempting to join game ID");
        console.logUint(gameId);
        console.log("with stake");
        console.logUint(stake);
        try scrabble.joinGame(gameId, stake, sig) {
            console.log("Player");
            console.logAddress(player);
            console.log("joined game ID");
            console.logUint(gameId);
        } catch {
            console.log("Failed to join game ID");
            console.logUint(gameId);
            console.log("for player");
            console.logAddress(player);
        }
    }

    /// @notice Submits a game result to the Scrabble contract
    /// @param gameId ID of the game to submit results for
    /// @param winnerIdx Index of the winner in the players array
    function submitResult(uint256 gameId, uint256 winnerIdx) public {
        gameId = bound(gameId, 1, scrabble.GameId());
        winnerIdx = bound(winnerIdx, 0, players.length - 1);
        address winner = players[winnerIdx];
        Scrabble.Game memory game = scrabble.getGame(gameId);
        uint32[] memory scores = new uint32[](game.players.length);
        for (uint256 i = 0; i < scores.length; i++) {
            scores[i] = uint32(bound(i, 0, 1000));
            console.log("Score for player");
            console.logAddress(game.players[i]);
            console.log("set to");
            console.logUint(scores[i]);
        }
        vm.prank(submitter);
        console.log("Submitting result for game ID");
        console.logUint(gameId);
        console.log("with winner");
        console.logAddress(winner);
        try scrabble.submitResult(gameId, winner, bytes32(0), scores, scrabble.getGame(gameId).scores.length) {
            console.log("Result submitted for game ID");
            console.logUint(gameId);
        } catch {
            console.log("Failed to submit result for game ID");
            console.logUint(gameId);
        }
    }

    /// @notice Invariant to ensure all player balances are non-negative
    function invariant_BalancesNonNegative() public {
        for (uint256 i = 0; i < players.length; i++) {
            uint256 ethBalance = wallet.getBalance(players[i], address(0));
            uint256 usdtBalance = wallet.getBalance(players[i], usdt);
            uint256 usdcBalance = wallet.getBalance(players[i], usdc);
            console.log("Checking balances for player");
            console.logAddress(players[i]);
            console.log("ETH:");
            console.logUint(ethBalance);
            console.log("USDT:");
            console.logUint(usdtBalance);
            console.log("USDC:");
            console.logUint(usdcBalance);
            assertGe(ethBalance, 0);
            assertGe(usdtBalance, 0);
            assertGe(usdcBalance, 0);
        }
    }
  

    /// @notice Generates EIP-712 signature for authentication
    /// @param player Address of the player to sign for
    /// @return Signature bytes for authentication
    function signAuth(address player) internal returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(keccak256("Auth(address player)"), player));

        // bytes32 digest = scrabble._hashTypedDataV4(structHash);

        bytes32 digest = scrabble.getDigest(structHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(address(0x3))), digest);
        console.log("Generated signature for player");
        console.logAddress(player);
        return abi.encodePacked(r, s, v);
    }
}