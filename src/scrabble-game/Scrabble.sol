// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "../libraries/PriceConverter.sol";
import {Wallet} from "../wallet/Wallet.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title Scrabble On-Chain Game Settlement
 * @author Adebakin Olujimi
 * @notice Handles creation, joining, and settlement of Scrabble games with wallet-based stakes.
 * @dev Uses EIP-712 typed data signatures for secure result submission and OpenZeppelin’s ReentrancyGuard.
 */
contract Scrabble is EIP712, ReentrancyGuard {
    // ───────────────
    // Custom Errors
    // ───────────────
    error Scrabble__WalletInteractionFailed();   // Wallet failed to transfer funds
    error Scrabble__InsufficientAmountForStake(); // Stake is below minimum
    error Scrabble__InsufficientWalletBalance(); // Player wallet doesn’t have enough balance
    error Scrabble__StakeMisMatch();             // Joiner’s stake doesn’t match creator’s stake
    error Scrabble__InvalidGame();               // Invalid game reference
    error Scrabble__AlreadyJoined();             // Someone already joined the game
    error Scrabble__InvalidWinner();             // Winner must be one of the two players
    error Scrabble__InvalidSignature();          // Invalid or expired signature
    error Scrabble__AlreadySettled();            // Game already settled
    error Scrabble__InvalidSigner();             // Signers didn’t match the two players
    error Scrabble__InvalidGamePairing();        // Player attempted to join their own game
    error Scrabble__InvalidRound();              // Round number mismatch
    error Scrabble__LobbyTimeExpired();          // Game lobby expired before join

    // ───────────────
    // Libraries
    // ───────────────
    // using PriceConverter for uint256; 
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ───────────────
    // State Variables
    // ───────────────

    /// @notice Reference to the shared wallet contract (handles balances & payouts)
    Wallet private immutable i_wallet;

    /// @notice When each game was created (for lobby expiry)
    mapping(uint256 => uint64) private s_createdAt;

    // AggregatorV3Interface private s_priceFeed; // (if price feed logic re-enabled)

    /// @notice Minimum stake required per game currently in wei but will need priceconverter for it to be in usd @edetan NB
    uint256 private constant MINIMUM_STAKE = 1e8; 

    /// @notice Global counter to track and assign new game IDs
    uint256 private s_gameCounter;

    /// @notice Max allowed delay for result signatures NB anti-replay freshness
    uint256 constant MAX_DELAY = 5 minutes;

    /// @notice Expected round number for each game increments after settlement
    mapping(uint256 => uint256) private s_expectedRound;

    /// @notice Last used nonce per game (monotonic to prevent replay)
    mapping(uint256 => uint256) private s_lastNonce;

    /// @notice Timeout window for joining a game lobby once the time lapse the gamme is cancelledd
    uint64 constant LOBBY_TIMEOUT = 10 minutes;

    /// @notice Core game struct
    struct Game {
        address player1;
        address player2;
        uint256 stake;
        bool fundsLocked;
        address winner;
        uint32 p1Score;
        uint32 p2Score;
        bytes32 finalBoardHash;
    }

    /// @notice Stores all games by ID
    mapping(uint256 => Game) private s_games;

    /// @notice Typed data struct hash for Scrabble game results (EIP-712)
    bytes32 private constant _SCRABBLE_RESULT_TYPEHASH = keccak256(
        "ScrabbleResult(uint256 gameId,address player1,address player2,address winner,bytes32 finalBoardHash,uint32 p1Score,uint32 p2Score,uint256 nonce,uint256 timestamp,uint256 roundNumber)"
    );

    // ───────────────
    // Events
    // ───────────────
    /// @notice Emitted when a game is created
    event GameCreated(uint256 indexed gameId, address indexed player1, uint256 stake);

    /// @notice Emitted when a player joins a game
    event GameJoined(uint256 indexed gameId, address indexed player2, uint256 stake);

    /// @notice Emitted when a game is settled
    event GameSettled(
        uint256 indexed gameId,
        address indexed winner,
        uint256 payout,
        bytes32 finalBoardHash,
        uint32 p1Score,
        uint32 p2Score
    );

    // ───────────────
    // Constructor
    // ───────────────

    /**
     * @notice Deploy Scrabble with an attached wallet contract
     * @param wallet Address of the wallet contract
     * @dev EIP72 to initialize the signer
     */
    constructor(
        address wallet
    ) EIP712("Scrabble", "1") {
        i_wallet = Wallet(wallet);
    }

    // ───────────────
    // Game Lifecycle
    // ───────────────

    /**
     * @notice Create a new Scrabble game
     * @param stakeAmount The stake amount in wei
     * @return gameId The ID of the newly created game
     * @dev Deducts stake from creator’s wallet and locks funds in-game
     */
    function createGame(uint256 stakeAmount) external nonReentrant returns (uint256 gameId) {
        if (stakeAmount > i_wallet.getBalance(msg.sender)) {
            revert Scrabble__InsufficientWalletBalance();
        }
        if (stakeAmount < MINIMUM_STAKE || stakeAmount == 0) {
            revert Scrabble__InsufficientAmountForStake();
        }

        bool success = i_wallet.deductFunds(msg.sender, stakeAmount);
        if (!success) revert Scrabble__WalletInteractionFailed();

        gameId = ++s_gameCounter;

        s_games[gameId] = Game({
            player1: msg.sender,
            player2: address(0),
            stake: stakeAmount,
            fundsLocked: true,
            winner: address(0),
            p1Score: 0,
            p2Score: 0,
            finalBoardHash: bytes32(0)
        });

        s_createdAt[gameId] = uint64(block.timestamp);

        emit GameCreated(gameId, msg.sender, stakeAmount);
    }

    /**
     * @notice Cancel a game if nobody joined within the lobby timeout
     * @param gameId ID of the game to cancel
     * @dev Refunds stake to creator if cancelled
     */
    function cancelGame(uint256 gameId) external nonReentrant {
        Game storage game = s_games[gameId];
        if (msg.sender != game.player1) revert Scrabble__InvalidGame();
        if (game.player2 != address(0)) revert Scrabble__AlreadyJoined();
        if (block.timestamp < s_createdAt[gameId] + LOBBY_TIMEOUT) revert Scrabble__LobbyTimeExpired();

        i_wallet.addWinnings(game.player1, game.stake); // refund
        game.fundsLocked = false;
    }

    /**
     * @notice Join an existing Scrabble game
     * @param gameId The ID of the game to join
     * @param stakeAmount Stake amount (must match creator’s stake)
     */
    function joinGame(uint256 gameId, uint256 stakeAmount) external nonReentrant {
        Game storage gameplay = s_games[gameId];

        if (msg.sender == gameplay.player1) revert Scrabble__InvalidGamePairing();
        if (stakeAmount != gameplay.stake) revert Scrabble__StakeMisMatch();
        if (gameplay.player1 == address(0)) revert Scrabble__InvalidGame();
        if (gameplay.player2 != address(0)) revert Scrabble__AlreadyJoined();

        bool success = i_wallet.deductFunds(msg.sender, stakeAmount);
        if (!success) revert Scrabble__WalletInteractionFailed();

        gameplay.player2 = msg.sender;

        emit GameJoined(gameId, msg.sender, stakeAmount);
    }

    /**
     * @notice Submit the final result of a game (both players must sign off-chain)
     * @param gameId ID of the game
     * @param winner Winner address (zero address = draw)
     * @param finalBoardHash Hash of final Scrabble board state
     * @param p1Score Score of player1
     * @param p2Score Score of player2
     * @param nonce Unique number to prevent replay
     * @param sigP1 Player1’s EIP-712 signature
     * @param sigP2 Player2’s EIP-712 signature
     * @param timestamp Timestamp attached to signature (freshness check)
     * @param roundNumber Round number expected for game (prevents stale resubmission)
     */
    function submitResult(
        uint256 gameId,
        address winner,
        bytes32 finalBoardHash,
        uint32 p1Score,
        uint32 p2Score,
        uint256 nonce,
        bytes calldata sigP1,
        bytes calldata sigP2,
        uint256 timestamp,
        uint256 roundNumber
    ) external nonReentrant {
        Game storage game = s_games[gameId];
        if (game.player1 == address(0) || game.player2 == address(0)) revert Scrabble__InvalidGame();

        // Nonce monotonicity check
        uint256 last = s_lastNonce[gameId];
        if (nonce <= last) revert Scrabble__InvalidSignature();
        s_lastNonce[gameId] = nonce;

        // Freshness checks
        if (timestamp > block.timestamp + 1 minutes || block.timestamp > timestamp + MAX_DELAY) {
            revert Scrabble__InvalidSignature();
        }

        if (!game.fundsLocked) revert Scrabble__AlreadySettled();
        if (winner != address(0) && winner != game.player1 && winner != game.player2) {
            revert Scrabble__InvalidWinner();
        }

        // Build typed data struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                _SCRABBLE_RESULT_TYPEHASH,
                gameId,
                game.player1,
                game.player2,
                winner,
                finalBoardHash,
                p1Score,
                p2Score,
                nonce,
                timestamp,
                roundNumber
            )
        );

        // Apply EIP-712 domain separation
        bytes32 digest = _hashTypedDataV4(structHash);

        // Enforce expected round
        if (roundNumber != s_expectedRound[gameId]) revert Scrabble__InvalidRound();

        // Recover signers
        address a = ECDSA.recover(digest, sigP1);
        address b = ECDSA.recover(digest, sigP2);
        bool ok = (a == game.player1 && b == game.player2) || (a == game.player2 && b == game.player1);
        if (!ok) revert Scrabble__InvalidSigner();

        // Payout logic
        uint256 totalPot;
        unchecked { totalPot = game.stake * 2; }

        if (winner == address(0)) {
            i_wallet.addWinnings(game.player1, game.stake);
            i_wallet.addWinnings(game.player2, game.stake);
        } else {
            i_wallet.addWinnings(winner, totalPot);
        }

        // Finalize
        s_expectedRound[gameId]++;
        game.winner = winner;
        game.finalBoardHash = finalBoardHash;
        game.p1Score = p1Score;
        game.p2Score = p2Score;
        game.fundsLocked = false;

        emit GameSettled(gameId, winner, totalPot, finalBoardHash, p1Score, p2Score);
    }

    // ───────────────
    // Getters
    // ───────────────

    /**
     * @notice Get full game struct by ID
     * @param gameId Game ID
     * @return Game struct
     */
    function getGame(uint256 gameId) external view returns (Game memory) {
        return s_games[gameId];
    }

    /**
     * @notice Returns next available game ID
     */
    function nextGameId() external view returns (uint256) {
        return s_gameCounter;
    }
}
