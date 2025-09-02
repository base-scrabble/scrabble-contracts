// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Scrabble} from "../src/scrabble-game/Scrabble.sol";
import {Wallet} from "../src/wallet/Wallet.sol";

/**
 * BatchGameCreator - Refactored for Base Sepolia (Chain ID: 84532)
 * - Creates actual on-chain transactions when run with --broadcast flag
 * - Saves transaction hashes in broadcast/BatchGameCreator.s.sol/84532/run-latest.json
 * - Removed problematic file operations that cause permission errors
 * - Fixed array declarations and type mismatches
 */
contract BatchGameCreator is Script {
    // ===== CONFIG =====
    uint256 private constant STAKE_AMOUNT = 1e6;
    uint256 private constant DEPOSIT_AMOUNT = 0.001 ether;
    uint256 private constant TOTAL_GAMES = 5;  // Reduced for testing - change as needed
    uint256 private constant BATCH_SIZE = 2;   // Reduced for testing - change as needed

    // ===== Contracts =====
    Scrabble public scrabble;
    Wallet public wallet;

    // ===== Participants =====
    address[4] private players;    // Fixed-size array
    address public submitter;
    address public backendSigner;

    // ===== Private keys (from env) =====
    uint256[4] private playerPks;  // Fixed-size array
    uint256 private deployerPk;
    uint256 private backendSignerPk;
    uint256 private submitterPk;

    // ===== Game tracking =====
    uint256 private currentGameId;

    // ====== MAIN ENTRY POINTS ======
    function setUp() public {
        console.log("\n=== BatchGameCreator Setup ===");
        _loadKeys();
        _initContracts();
        _initPlayers();
        _printSetupInfo();
        console.log("Setup completed successfully\n");
    }

    function run() external {
        console.log("=== Starting Batch Game Creation ===");
        console.log("Chain ID: 84532 (Base Sepolia)");
        console.log("Total Games:", TOTAL_GAMES);
        console.log("Batch Size:", BATCH_SIZE);
        console.log("Stake Amount:", STAKE_AMOUNT);
        
        // Step 1: Authorize Scrabble contract
        _authorizeScrabble();
        
        // Step 2: Fund all players
        _fundAllPlayers();
        
        // Step 3: Create and process all game batches
        _processAllGameBatches();
        
        console.log("\n=== Batch Creation Complete ===");
        console.log("Transaction hashes saved in: broadcast/BatchGameCreator.s.sol/84532/run-latest.json");
        console.log("Verify transactions at: https://sepolia.basescan.org/");
    }

    // ===== SETUP FUNCTIONS =====
    function _loadKeys() internal {
        console.log("Loading private keys from environment...");
        
        deployerPk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        backendSignerPk = vm.envUint("BACKEND_SIGNER_PK");
        submitterPk = vm.envUint("SUBMITTER_PK");

        // Load player private keys
        playerPks[0] = vm.envUint("PLAYER1_PK");
        playerPks[1] = vm.envUint("PLAYER2_PK");
        playerPks[2] = vm.envUint("PLAYER3_PK");
        playerPks[3] = vm.envUint("PLAYER4_PK");
        
        console.log("Private keys loaded successfully");
    }

    function _initContracts() internal {
        console.log("Initializing contracts...");
        
        address scrabbleAddr = vm.envAddress("BASE_SCRABBLE_ADDRESS");
        address walletAddr = vm.envAddress("BASE_SEPOLIA_WALLET_ADDRESS");

        scrabble = Scrabble(scrabbleAddr);
        wallet = Wallet(walletAddr);

        console.log("Scrabble Contract:", scrabbleAddr);
        console.log("Wallet Contract:", walletAddr);
    }

    function _initPlayers() internal {
        console.log("Generating player addresses...");
        
        for (uint256 i = 0; i < 4; i++) {
            players[i] = vm.addr(playerPks[i]);
        }
        backendSigner = vm.addr(backendSignerPk);
        submitter = vm.addr(submitterPk);
        
        console.log("Player addresses generated");
    }

    function _printSetupInfo() internal view {
        console.log("\n--- PARTICIPANTS ---");
        console.log("Deployer:", vm.addr(deployerPk));
        console.log("Backend Signer:", backendSigner);
        console.log("Submitter:", submitter);
        
        for (uint256 i = 0; i < 4; i++) {
            console.log(string.concat("Player ", vm.toString(i + 1), ":"), players[i]);
        }
    }

    // ===== OPERATIONAL FUNCTIONS =====
    function _authorizeScrabble() internal {
        console.log("\n--- AUTHORIZING SCRABBLE CONTRACT ---");
        
        vm.startBroadcast(deployerPk);
        wallet.setAuthorizedCaller(address(scrabble), true);
        vm.stopBroadcast();
        
        console.log("Scrabble contract authorized in Wallet");
    }

    function _fundAllPlayers() internal {
        console.log("\n--- FUNDING PLAYERS ---");
        
        for (uint256 i = 0; i < 4; i++) {
            console.log(string.concat("Funding Player ", vm.toString(i + 1), "..."));
            
            vm.startBroadcast(playerPks[i]);
            bytes memory sig = _getWalletSig(players[i]);
            wallet.depositETH{value: DEPOSIT_AMOUNT}(sig);
            vm.stopBroadcast();
            
            console.log(string.concat("Player ", vm.toString(i + 1), " funded with"), DEPOSIT_AMOUNT);
        }
        
        console.log("All players funded successfully");
    }

    function _processAllGameBatches() internal {
        console.log("\n--- PROCESSING GAME BATCHES ---");
        
        uint256 numFullBatches = TOTAL_GAMES / BATCH_SIZE;
        uint256 remainder = TOTAL_GAMES % BATCH_SIZE;
        
        console.log("Full batches:", numFullBatches);
        console.log("Remainder games:", remainder);

        // Process full batches
        for (uint256 b = 0; b < numFullBatches; b++) {
            _processBatch(b, BATCH_SIZE);
        }

        // Process remainder games
        if (remainder > 0) {
            _processBatch(numFullBatches, remainder);
        }
    }

    function _processBatch(uint256 batchIdx, uint256 gamesInBatch) internal {
        uint256 startGame = batchIdx * BATCH_SIZE + 1;
        uint256 endGame = startGame + gamesInBatch - 1;
        
        console.log(string.concat("\n--- BATCH ", vm.toString(batchIdx + 1), " ---"));
        console.log(string.concat("Games ", vm.toString(startGame), " to ", vm.toString(endGame)));

        for (uint256 g = 0; g < gamesInBatch; g++) {
            uint256 gameNumber = startGame + g;
            _createAndPlayGame(gameNumber);
        }
        
        console.log(string.concat("Batch ", vm.toString(batchIdx + 1), " completed"));
    }

    function _createAndPlayGame(uint256 gameNumber) internal {
        console.log(string.concat("\n> Creating Game ", vm.toString(gameNumber)));
        
        // 1. Player 1 creates the game
        vm.startBroadcast(playerPks[0]);
        bytes memory createSig = _getScrabbleSig(players[0]);
        uint256 actualGameId = scrabble.createGame(STAKE_AMOUNT, address(0), createSig);
        vm.stopBroadcast();
        
        console.log("Game created with ID:", actualGameId);
        console.log("Creator:", players[0]);

        // 2. Players 2-4 join the game
        for (uint256 i = 1; i < 4; i++) {
            vm.startBroadcast(playerPks[i]);
            bytes memory joinSig = _getScrabbleSig(players[i]);
            scrabble.joinGame(actualGameId, STAKE_AMOUNT, joinSig);
            vm.stopBroadcast();
            
            console.log(string.concat("Player ", vm.toString(i + 1), " joined:"), players[i]);
        }

        // 3. Submit game result (Player 1 wins)
        vm.startBroadcast(submitterPk);
        
        uint32[] memory scores = new uint32[](4);
        scores[0] = 100;  // Player 1 wins
        scores[1] = 90;
        scores[2] = 80;
        scores[3] = 70;
        
        bytes32 finalBoard = bytes32(0);
        scrabble.submitResult(actualGameId, players[0], finalBoard, scores, 0);
        
        vm.stopBroadcast();
        
        console.log("Game", actualGameId, "completed - Winner:", players[0]);
        console.log("Final scores: [100, 90, 80, 70]");
    }

    // ===== SIGNATURE HELPERS =====
    function _getWalletSig(address player) internal view returns (bytes memory) {
        uint256 nonce = wallet.getNonce(player);
        bytes32 structHash = keccak256(abi.encode(wallet._AUTH_TYPEHASH(), player, nonce));
        bytes32 digest = wallet.getDigest(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(backendSignerPk, digest);
        return abi.encodePacked(r, s, v);
    }

    function _getScrabbleSig(address player) internal view returns (bytes memory) {
        bytes32 AUTH_TYPEHASH = keccak256("Auth(address player)");
        bytes32 structHash = keccak256(abi.encode(AUTH_TYPEHASH, player));
        bytes32 digest = scrabble.getDigest(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(backendSignerPk, digest);
        return abi.encodePacked(r, s, v);
    }

    // ===== UTILITY FUNCTIONS =====
    function getPlayerAddresses() external view returns (address[4] memory) {
        return players;
    }
    
    function getContractAddresses() external view returns (address scrabbleAddr, address walletAddr) {
        return (address(scrabble), address(wallet));
    }
}