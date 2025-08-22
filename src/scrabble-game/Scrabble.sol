// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "../libraries/PriceConverter.sol";
import {Wallet} from "../wallet/Wallet.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Scrabble is ReentrancyGuard{
    error  Scrabble__WalletInteractionFailed();
    error Scrabble__InsufficientAmountForStake();
    error Scrabble__InsufficientWalletBalance();
    error Scrabble__StakeMisMatch();
    error Scrabble__InvalidGame();
    error Scrabble__AlreadyJoined();
    error Scrabble__InvalidWinner();
    error Scrabble__InvalidSignature();


    // using PriceConverter for uint256;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    Wallet private immutable i_wallet;
    // AggregatorV3Interface private s_priceFeed;

    uint256 private constant MINIMUM_STAKE = 1;
    uint256 private s_gameCounter;

    struct Game{
        address player1;
        address player2;
        uint256 stake;
        bool fundsLocked;
        address winner;
        uint32 p1Score;
        uint32 p2Score;
        bytes32 finalBoardHash;
    }

    mapping (uint256 => Game) private s_games;

    event GameCreated(uint256 indexed gameId, address indexed player1, uint256 stake);
    event GameJoined(uint256 indexed gameId, address indexed player2);
    // event GameCancelled(uint256 indexed gameId, address indexed by);
    event GameSettled(
        uint256 indexed gameId,
        address indexed winner,
        uint256 payout,
        bytes32 finalBoardHash,
        uint32 p1Score,
        uint32 p2Score
    );

    constructor(
        // address priceFeed,
        address wallet
    ){
        // s_priceFeed = AggregatorV3Interface(priceFeed);
        i_wallet = Wallet(wallet);
    }
    /** 
    @notice Creates a new Scrabble game with a specified stake amount.
    @param stakeAmount The amount of ETH to stake for the game.
    @return gameId The unique identifier for the created game.
    @dev The stake amount must be greater than or equal to the minimum stake defined in the
    **/

    function createGame(uint256 stakeAmount) external nonReentrant returns(uint256 gameId){
        if(stakeAmount/*.getConversionRate(s_priceFeed)*/ > i_wallet.getBalance(msg.sender)){
            revert Scrabble__InsufficientWalletBalance();
        }
        if(stakeAmount/*.getConversionRate(s_priceFeed)*/ < MINIMUM_STAKE){
            revert Scrabble__InsufficientAmountForStake();
        }

        bool success = i_wallet.deductFunds(msg.sender, stakeAmount);
            if(!success){
                revert Scrabble__WalletInteractionFailed();
            }
        
        gameId = s_gameCounter++;
        s_games[gameId] = Game({
            player1 : msg.sender,
            player2 : address(0),
            stake : stakeAmount,
            fundsLocked : true,
            winner : address(0),
            p1Score : 0,
            p2Score :0,
            finalBoardHash: bytes32(0)
        });
        emit GameCreated(gameId, msg.sender, stakeAmount);
    }
    /**
     * 
     * @param gameId The ID of the game to join.
     * @dev The stake amount must match the game's stake.
     * @dev The player must not already be in the game.
     * @dev The player must have sufficient funds in their wallet.
     * @dev The function will revert if the game is invalid or if the player has already
     * @param stakeAmount The amount of ETH to stake for the game.
     */
    function joinGame(uint256 gameId, uint256 stakeAmount) external nonReentrant{
        Game storage gameplay = s_games[gameId];
        if(stakeAmount != gameplay.stake){
            revert Scrabble__StakeMisMatch();
        }
        if (gameplay.player1 == address(0)) {
            revert Scrabble__InvalidGame();
        }
        if (gameplay.player2 != address(0)){
            revert Scrabble__AlreadyJoined();
        }
        bool success = i_wallet.deductFunds(msg.sender, stakeAmount);
        if(!success){
            revert Scrabble__WalletInteractionFailed();
        }

        gameplay.player2 = msg.sender;
        emit GameJoined(gameId, msg.sender);
    }
    /** 
     * @notice Submits the final result of a Scrabble game.
     * @dev Requires signatures from both players to confirm result.
     * @param gameId The ID of the game.
     * @param winner The address of the winner (zero if draw).
     * @param finalBoardHash Hash of final board state for verification.
     * @param p1Score Player 1's score.
     * @param p2Score Player 2's score.
     * @param nonce Random value to prevent replay attacks.
     * @param sigP1 Signature from player 1.
     * @param sigP2 Signature from player 2. 
     */

     function submitResult(
        uint256 gameId,
        address winner,
        bytes32 finalBoardHash,
        uint32 p1Score,
        uint32 p2Score,
        uint256 nonce,
        bytes calldata sigP1,
        bytes calldata sigP2
    ) external nonReentrant {
        Game storage game = s_games[gameId];
        if (game.player1 == address(0) || game.player2 == address(0)) revert Scrabble__InvalidGame();
        if (winner != address(0) && winner != game.player1 && winner != game.player2) {
            revert Scrabble__InvalidWinner();
        }

        // Build the exact digest both players must have signed (simple eth_sign flow)
        // Include chainId and this contract address to prevent cross-chain/contract replays.
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "ScrabbleResult(uint256 chainId,address contractAddr,uint256 gameId,address player1,address player2,address winner,bytes32 finalBoardHash,uint32 p1Score,uint32 p2Score,uint256 nonce)"
                ),
                block.chainid,
                address(this),
                gameId,
                game.player1,
                game.player2,
                winner,
                finalBoardHash,
                p1Score,
                p2Score,
                nonce
            )
        );
        bytes32 ethSigned = structHash.toEthSignedMessageHash();

        // Recover signers
        address r1 = ethSigned.recover(sigP1);
        address r2 = ethSigned.recover(sigP2);
        if (r1 != game.player1 || r2 != game.player2){
            revert Scrabble__InvalidSignature();
        }

        // Payouts
        uint256 totalPot = game.stake * 2;
        if (winner == address(0)) {
            // draw: both refunded stake
            i_wallet.addWinnings(game.player1, game.stake);
            i_wallet.addWinnings(game.player2, game.stake);
        } else {
            i_wallet.addWinnings(winner, totalPot);
        }

        // Finalize
        game.winner = winner;
        game.finalBoardHash = finalBoardHash;
        game.p1Score = p1Score;
        game.p2Score = p2Score;
        game.fundsLocked = false;
        

        emit GameSettled(gameId, winner, totalPot, finalBoardHash, p1Score, p2Score);
    }

}
