// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "../libraries/PriceConverter.sol";
import {Wallet} from "../wallet/Wallet.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {AccessManager} from "../access/AccessManager.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Scrabble On Chain Game Settlement
 * @author Adebakin Olujimi
 * @notice Handles creation, joining, and settlement of Scrabble games with wallet-based stakes.
 * @dev Uses EIP-712 typed data signatures for secure result submission and OpenZeppelin’s ReentrancyGuard.
 */
contract Scrabble is EIP712, AccessManager {
    // ───────────────
    // Custom Errors
    // ───────────────
    error Scrabble__WalletInteractionFailed(); // Wallet failed to transfer funds
    error Scrabble__InsufficientAmountForStake(); // Stake is below minimum
    error Scrabble__InsufficientWalletBalance(); // Player wallet doesn’t have enough balance
    error Scrabble__StakeMisMatch(); // Joiner’s stake doesn’t match creator’s stake
    error Scrabble__InvalidGame(); // Invalid game reference
    error Scrabble__AlreadyJoined(); // Someone already joined the game
    error Scrabble__InvalidWinner(); // Winner must be one of the two players
    error Scrabble__InvalidSignature(); // Invalid or expired signature
    error Scrabble__AlreadySettled(); // Game already settled
    error Scrabble__InvalidSigner(); // Signers didn’t match the two players
    error Scrabble__InvalidGamePairing(); // Player attempted to join their own game
    error Scrabble__InvalidRound(); // Round number mismatch
    error Scrabble__LobbyTimeExpired(); // Game lobby expired before join
    error NotAuthenticated();
    error Scrabble__InvalidSubmitter();
    error Scrabble__UnsupportedToken();

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
    /// @dev An immutable variable that stores the address of the Wallet contract. It's set in the constructor and cannot be changed.
    Wallet private immutable i_wallet;

    /// @notice A mapping to track the creation time of each game.
    /// @dev The key is the `gameId` and the value is the `uint64` timestamp of creation. Used to determine lobby expiry.
    mapping(uint256 => uint64) private s_createdAt;

    // AggregatorV3Interface private s_priceFeed; // (if price feed logic re-enabled)

    /// @notice The minimum stake required to join a game.
    /// @dev A constant representing a minimum stake of 0.1 ether (1e17 wei) but is currently set at 1e8 wei. A price converter will be needed to set this value in USD.
    uint256 private constant MINIMUM_STAKE = 1e6;

    /// @notice A global counter for assigning new game IDs.
    /// @dev Increments with each new game created to ensure unique identifiers.
    uint256 private s_gameCounter;

    /// @notice The maximum allowed delay between signing a result and submitting it.
    /// @dev A constant of 5 minutes used to prevent replay attacks and ensure transaction freshness.
    uint256 constant MAX_DELAY = 5 minutes;

    /// @notice A mapping to track the expected round number for each game.
    /// @dev The key is the `gameId` and the value is the current round number. Incremented after each game is settled.
    mapping(uint256 => uint256) private s_expectedRound;

    /// @notice A mapping to store the last used nonce for each player in a specific game.
    /// @dev The keys are `gameId` and `player address`, and the value is the `nonce`. This prevents replay attacks.
    mapping(uint256 => mapping(address => uint256)) private s_lastNonce;

    /// @notice The time window for players to join a game lobby before it's canceled.
    /// @dev A constant of 10 minutes (600 seconds) after which an incomplete game can be canceled.
    uint64 constant LOBBY_TIMEOUT = 10 minutes;

    /// @notice A mapping to store all games.
    /// @dev The key is the `gameId` and the value is the `Game` struct containing all game-related data.
    mapping(uint256 => Game) private s_games;

    /// @notice The address of the designated submitter who can submit game results.
    /// @dev An immutable variable set in the constructor to grant specific permissions.
    address private immutable i_submitter;

    /// @notice The address of the backend signer.
    /// @dev An immutable variable set in the constructor. The backend signs messages on behalf of players to call functions like `createGame` and `joinGame`.
    address private immutable i_backendSigner;

    /// @notice The maximum number of players allowed in a game.
    /// @dev A constant of 4 players, ensuring games have a fixed size.
    uint32 private immutable MAX_PLAYER = 4;

    /// @notice The keccak256 hash of the `Auth` typed data struct.
    /// @dev A private constant used for EIP-712 signature verification to authenticate players.
    bytes32 private constant _AUTH_TYPEHASH = keccak256("Auth(address player)");

    address private immutable i_usdt;
address private immutable i_usdc;
  AggregatorV3Interface private immutable i_ethUsdFeed; 

    /// @notice Typed data struct hash for Scrabble game results (EIP-712)
    bytes32 private constant _SCRABBLE_RESULT_TYPEHASH = keccak256(
        "ScrabbleResult(uint256 gameId,address player1,address player2,address winner,bytes32 finalBoardHash,uint32 p1Score,uint32 p2Score,uint256 nonce,uint256 timestamp,uint256 roundNumber)"
    );

    ///////////////////////////////
    //////// MODIFIERS ///////////
    //////////////////////////////

    modifier onlySubmitter() {
        if (msg.sender != i_submitter) revert Scrabble__InvalidSubmitter();
        _;
    }

    modifier whenNotPaused() virtual override {
        require(!paused(), "System paused");
        _;
    }

    // Modifier to allow only backend-approved addresses
    modifier onlyAuthenticated(bytes calldata backendSig) {
        // Create the structured hash of the "Auth" type with the player address
        bytes32 structHash = keccak256(abi.encode(_AUTH_TYPEHASH, msg.sender));

        // Convert to EIP-712 digest
        bytes32 digest = _hashTypedDataV4(structHash);

        // Recover signer from signature
        address recovered = ECDSA.recover(digest, backendSig);

        // Ensure the recovered address matches the backend signer
        if (recovered != i_backendSigner) revert NotAuthenticated();

        _;
    }

    /// @notice Core game struct. Players/scores arrays share the same index order.
    struct Game {
        address[] players; // creator at index 0; up to 4 players total (per your join guard)
        uint256 stake; // stake per player
        address token;
        bool fundsLocked; // true after creation until settle/cancel
        address winner; // zero address = draw
        uint32[] scores; // scores[i] corresponds to players[i]
        bytes32 finalBoardHash; // content-addressed hash for post-game verification
    }

    // ───────────────
    // Events
    // ───────────────
    /// @notice Emitted when a game is created
    event GameCreated(uint256 indexed gameId, address indexed player, address token, uint256 stake);

    /// @notice Emitted when a player joins a game
    event GameJoined(uint256 indexed gameId, address indexed player, uint256 stake);

    /// @notice Emitted when a game is cancelled
    event GameCancelled(uint256 indexed gameId, address indexed player);

    /// @notice Emitted when a game is settled
    /// @notice Emitted when a game is settled
    /// @param gameId The ID of the game
    /// @param winner The address of the winner (zero address for draw)
    /// @param payout Total payout amount
    /// @param finalBoardHash Hash of the final game board
    /// @param scores Array of player scores in the same order as game.players
    event GameSettled(
        uint256 indexed gameId,
        address indexed winner,
        uint256 payout,
        bytes32 finalBoardHash,
        uint32[] scores
    );

    // ───────────────
    // Constructor
    // ───────────────

    /**
     * @notice Deploy Scrabble with a wallet, admin, submitter and backend signer.
     * @param wallet Address of the shared Wallet contract.
     * @param _superAdmin Initial AccessManager admin.
     * @param submitter Address allowed to call simplified `submitResult`.
     * @param backendSigner EOA used by your backend to EIP-712-authorize calls.
     */
    constructor(
    address wallet, 
    address _superAdmin, 
    address submitter, 
    address backendSigner,
    address usdt,
    address usdc,
    address ethUsdPriceFeed )
        EIP712("Scrabble", "1")
        AccessManager(_superAdmin)
    {
        i_wallet = Wallet(wallet);
        i_submitter = submitter;
        i_backendSigner = backendSigner;
        i_usdt = usdt;
        i_usdc = usdc;
        i_ethUsdFeed = AggregatorV3Interface(ethUsdPriceFeed);
    }

    // ───────────────
    // Game Lifecycle
    // ───────────────

    /**
     * @notice Create a new Scrabble game
     * @param stakeAmount The stake amount in USD
     * @return gameId The ID of the newly created game
     * @param backendSig EIP-712 signature from backend authorizing msg.sender.
     * @param token The token address to use for staking (address(0) for ETH, or USDT/USDC addresses)
     * @dev Deducts stake from creator’s wallet and locks funds in-game
     */
    function createGame(uint256 stakeAmount, address token, bytes calldata backendSig)
        external
        nonReentrant
        onlyAuthenticated(backendSig)
        notBlacklisted
        whenNotPaused
        returns (uint256 gameId)
    {
        // CHECKS

        // Validate token
        if (!_isSupportedToken(token)) revert Scrabble__UnsupportedToken();

        if (stakeAmount < MINIMUM_STAKE || stakeAmount == 0) {
            revert Scrabble__InsufficientAmountForStake();
        }

        if (stakeAmount > i_wallet.getBalance(msg.sender, token)) {
            revert Scrabble__InsufficientWalletBalance();
        }

        // EFFECTS
        gameId = ++s_gameCounter;

        // Initialize empty arrays for players and scores
        address[] memory initialPlayers;
        initialPlayers[0] = msg.sender;
        uint32[] memory initialScores;
        initialScores[0] = 0;


        s_games[gameId] = Game({
            players: initialPlayers,
            stake: stakeAmount,
            token: token,
            fundsLocked: true,
            winner: address(0),
            scores: initialScores,
            finalBoardHash: bytes32(0)
           
        });

        // set creator (index 0) & initial score
        s_games[gameId].players.push(msg.sender);

        s_games[gameId].scores.push(0);

        s_createdAt[gameId] = uint64(block.timestamp);

        // INTERACTIONS (external after effects)
        bool success = i_wallet.deductFunds(msg.sender, token, stakeAmount);
        if (!success) revert Scrabble__WalletInteractionFailed();

        emit GameCreated(gameId, msg.sender, token, stakeAmount);
    }

    /**
     * @notice Cancel a Scrabble game if no other players joined within the lobby timeout.
     * @dev Only the game creator can cancel. Refunds the creator's stake and unlocks the game.
     *      Reverts if the lobby timeout has not yet expired or if other players have already joined.
     * @param gameId The ID of the game to cancel.
     * @param backendSig EIP-712 signature from backend authorizing msg.sender.
     */
    function cancelGame(uint256 gameId, bytes calldata backendSig)
        external
        onlyAuthenticated(backendSig)
        notBlacklisted
        whenNotPaused
        nonReentrant
    {
        Game storage game = s_games[gameId];

        // CHECKS
        if (game.players.length == 0 || msg.sender != game.players[0]) revert Scrabble__InvalidGame();
        // Ensure only the creator can cancel the game
        if (msg.sender != game.players[0]) revert Scrabble__InvalidGame();

        // Ensure lobby timeout has passed
        if (block.timestamp < s_createdAt[gameId] + LOBBY_TIMEOUT) revert Scrabble__LobbyTimeExpired();

        // Only cancel if nobody else joined
        if (game.players.length > 1) revert Scrabble__AlreadyJoined();
        if (!game.fundsLocked) revert Scrabble__AlreadySettled();
        // Refund the creator
        // i_wallet.addWinnings(game.players[0], game.stake);

        // EFFECTS
        // Unlock funds
        game.fundsLocked = false;

        // INTERACTIONS
        i_wallet.addWinnings(game.players[0], game.token, game.stake);
        emit GameCancelled(gameId, msg.sender);
    }

    /**
     * @notice Join an existing game; locks joiner's stake.
     * @param gameId The game id to join.
     * @param stakeAmount Must equal the creator's stake.
     * @param backendSig EIP-712 signature from backend authorizing msg.sender.
     */
    function joinGame(uint256 gameId, uint256 stakeAmount, bytes calldata backendSig)
        external
        nonReentrant
        notBlacklisted
        whenNotPaused
        onlyAuthenticated(backendSig)
    {
        Game storage gameplay = s_games[gameId];

        // CHECKS
        if (gameplay.players.length == 0) revert Scrabble__InvalidGame();
        if (gameplay.players.length >= MAX_PLAYER) revert Scrabble__AlreadyJoined();
        for (uint256 i = 0; i < gameplay.players.length; i++) {
            if (gameplay.players[i] == msg.sender) revert Scrabble__InvalidGamePairing(); // cannot join twice
        }

        if (stakeAmount != gameplay.stake) revert Scrabble__StakeMisMatch();

        // EFFECTS
        gameplay.players.push(msg.sender);
        gameplay.scores.push(0);

        // INTERACTIONS
        bool success = i_wallet.deductFunds(msg.sender, gameplay.token, stakeAmount);
        if (!success) revert Scrabble__WalletInteractionFailed();

        emit GameJoined(gameId, msg.sender, stakeAmount);
    }

    // /**
    //  * @notice Submit the final result of a game
    //  * @dev Each player must provide a valid EIP-712 signature off-chain
    //  * @param gameId The ID of the game being submitted
    //  * @param winner The winner's address (zero address indicates a draw)
    //  * @param finalBoardHash The hash of the final Scrabble board
    //  * @param scores Array of player scores, must match the order of game.players
    //  * @param nonce Unique number to prevent replay attacks
    //  * @param sigs Array of EIP-712 signatures, one per player
    //  * @param timestamp Timestamp from when signatures were created (used for freshness)
    //  * @param roundNumber Expected round number for the game (prevents stale submissions)
    //  */

    // function submitResult(
    //     uint256 gameId,
    //     address winner,
    //     bytes32 finalBoardHash,
    //     uint32[] calldata scores,
    //     uint256 nonce,
    //     bytes[] calldata sigs,
    //     uint256 timestamp,
    //     uint256 roundNumber
    // ) external nonReentrant {
    //     Game storage game = s_games[gameId];
    //     uint256 playerCount = game.players.length;

    //     // Validate input array lengths
    //     if (scores.length != playerCount) revert Scrabble__InvalidRound();
    //     if (sigs.length != playerCount) revert Scrabble__InvalidSignature();

    //     // Nonce monotonicity check
    //     // uint256 last = s_lastNonce[gameId];
    //     uint256 last = s_lastNonce[gameId][msg.sender];

    //     if (nonce <= last) revert Scrabble__InvalidSignature();
    //     s_lastNonce[gameId][msg.sender] = nonce;

    //     // Freshness check
    //     if (timestamp > block.timestamp + 1 minutes || block.timestamp > timestamp + MAX_DELAY) {
    //         revert Scrabble__InvalidSignature();
    //     }

    //     // Game must not already be settled
    //     if (!game.fundsLocked) revert Scrabble__AlreadySettled();

    //     // Winner must be a valid player or zero for draw
    //     if (winner != address(0)) {
    //         bool validWinner = false;
    //         for (uint256 i = 0; i < playerCount; i++) {
    //             if (game.players[i] == winner) {
    //                 validWinner = true;
    //                 break;
    //             }
    //         }
    //         if (!validWinner) revert Scrabble__InvalidWinner();
    //     }

    //     // Recover each player's signer and update scores
    //     for (uint256 i = 0; i < playerCount; i++) {
    //         bytes32 structHash = keccak256(
    //             abi.encode(
    //                 _SCRABBLE_RESULT_TYPEHASH,
    //                 gameId,
    //                 game.players[i],
    //                 winner,
    //                 finalBoardHash,
    //                 scores[i],
    //                 nonce,
    //                 timestamp,
    //                 roundNumber
    //             )
    //         );

    //         bytes32 digest = _hashTypedDataV4(structHash);
    //         address recovered = ECDSA.recover(digest, sigs[i]);
    //         if (recovered != game.players[i]) revert Scrabble__InvalidSigner();

    //         game.scores[i] = scores[i];
    //     }

    //     // Payout logic
    //     uint256 totalPot;
    //     unchecked {
    //         totalPot = game.stake * playerCount;
    //     }

    //     if (winner == address(0)) {
    //         // Draw: refund each player
    //         for (uint256 i = 0; i < playerCount; i++) {
    //             i_wallet.addWinnings(game.players[i], game.stake);
    //         }
    //     } else {
    //         // Winner takes all
    //         i_wallet.addWinnings(winner, totalPot);
    //     }

    //     // Finalize
    //     s_expectedRound[gameId]++;
    //     game.winner = winner;
    //     game.finalBoardHash = finalBoardHash;
    //     game.fundsLocked = false;

    //     emit GameSettled(gameId, winner, totalPot, finalBoardHash, scores);
    // }

    /**
     * @notice Submit final result (centralized submitter flow).
     * @notice Followed the CEI Pattern for good smart contract practice
     * @dev Winner can be address(0) for draw. Pays out & unlocks the pot.
     * @param gameId The game id.
     * @param winner Winner address (zero = draw).
     * @param finalBoardHash Content hash of final board state.
     * @param scores Player scores aligned with players array.
     * @param roundNumber Must equal s_expectedRound[gameId].
     */
    function submitResult(
        uint256 gameId,
        address winner,
        bytes32 finalBoardHash,
        uint32[] calldata scores,
        uint256 roundNumber
    ) external nonReentrant whenNotPaused onlySubmitter {
        Game storage game = s_games[gameId];
        uint256 playerCount = game.players.length;

        // CHECKS
        if (playerCount == 0) revert Scrabble__InvalidGame();
        if (scores.length != playerCount) revert Scrabble__InvalidRound();
        if (!game.fundsLocked) revert Scrabble__AlreadySettled();
        if (roundNumber != s_expectedRound[gameId]) revert Scrabble__InvalidRound();

        // validate winner
        if (winner != address(0)) {
            bool validWinner = false;
            for (uint256 i = 0; i < playerCount; i++) {
                if (game.players[i] == winner) {
                    validWinner = true;
                    break;
                }
            }
            if (!validWinner) revert Scrabble__InvalidWinner();
        }

        // Store scores
        //   EFFECTS
        for (uint256 i = 0; i < playerCount; i++) {
            game.scores[i] = scores[i];
        }

        game.winner = winner;
        game.finalBoardHash = finalBoardHash;
        game.fundsLocked = false;
        s_expectedRound[gameId]++;

        // Payout logic
        // INTERACTIONS
        uint256 totalPot = game.stake * playerCount;
        if (winner == address(0)) {
            // draw: refund each player
            for (uint256 i = 0; i < playerCount; i++) {
                i_wallet.addWinnings(game.players[i], game.token, game.stake);
            }
        } else {
            // winner takes all
            i_wallet.addWinnings(winner, game.token, totalPot);
        }

        emit GameSettled(gameId, winner, totalPot, finalBoardHash, scores);
    }

    function _isSupportedToken(address token) internal view returns (bool) {
    return (token == address(0) || token == i_usdt || token == i_usdc);
}
    // Any function with access control
function emergencyPause() external onlyRole(ADMIN_ROLE) {
    _pause(); 
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
    function GameId() external view returns (uint256) {
        return s_gameCounter;
    }

    /**
     * @notice Returns the last assigned game id.
     * @dev If you want the *next* id to be created, add +1.
     */
    function nextGameId() external view returns (uint256) {
        return s_gameCounter + 1;
    }
}
