// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/scrabble-game/Scrabble.sol";
import "../src/wallet/Wallet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ScrabbleUnitTest is Test {
    Scrabble scrabble;
    Wallet wallet;

    address superAdmin = address(0x1001);
    address submitter = address(0x1002);
    uint256 backendPk = 0xBEEF;
    address backendSigner;
    address player1 = address(0x1004);
    uint256 player1Pk = 0xCAFE; // example private key
    address player2 = address(0x1005);
    uint256 player2Pk = 0xDEAD; // example private key
    address usdt = address(0x1006);
    address usdc = address(0x1007);
    address priceFeed = address(0x1008);

    function setUp() public {
        backendSigner = vm.addr(backendPk);

        // Mock price feed
        vm.etch(priceFeed, bytes("mock"));
        vm.mockCall(
            priceFeed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, 2000e8, 0, 0, 0)
        );

        // Mock tokens
        vm.etch(usdt, bytes("mock"));
        vm.etch(usdc, bytes("mock"));

        // Deploy Wallet
        wallet = new Wallet(priceFeed, superAdmin, usdt, backendSigner, usdc);
        console.log("Wallet deployed at");
        console.log(address(wallet));

        // Deploy Scrabble
        scrabble = new Scrabble(address(wallet), superAdmin, submitter, backendSigner, usdt, usdc, priceFeed);
        console.log("Scrabble deployed at");
        console.log(address(scrabble));

        // Authorize Scrabble as caller
        vm.prank(superAdmin);
        wallet.setAuthorizedCaller(address(scrabble), true);
        console.log("Authorized Scrabble as caller in Wallet by superAdmin");
        console.log(superAdmin);
    }

    /// -------------------------
    /// Helper: sign EIP-712 auth
    /// -------------------------
    function signAuth(address player, uint256 pk) internal view returns (bytes memory) {
        uint256 nonce = wallet.getNonce(player);
        bytes32 structHash = keccak256(abi.encode(wallet._AUTH_TYPEHASH(), player, nonce));
        bytes32 digest = wallet.getDigest(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);

        console.log("Generated signature for player:");
        console.log(player);

        return abi.encodePacked(r, s, v);
    }

    /// -------------------------
    /// Tests
    /// -------------------------
    function test_CreateGame() public {
        vm.deal(player1, 1 ether);
        bytes memory sig = signAuth(player1, player1Pk);

        console.log("Depositing 1 ETH for player1:");
        console.log(player1);
        vm.prank(player1);
        wallet.depositETH{value: 1 ether}(sig);

        console.log("Creating game with player1:");
        console.log(player1);
        vm.prank(player1);
        uint256 gameId = scrabble.createGame(1e6, address(0), sig);

        address firstPlayer = scrabble.getGame(gameId).players[0];
        console.log("Game ID:");
        console.log(gameId);
        console.log("First player in game:");
        console.log(firstPlayer);

        assertEq(firstPlayer, player1, "First player should be player1");
    }

    function test_JoinGame() public {
        // Player1 deposits & creates game
        vm.deal(player1, 1 ether);
        bytes memory sig1 = signAuth(player1, player1Pk);
        vm.prank(player1);
        wallet.depositETH{value: 1 ether}(sig1);
        vm.prank(player1);
        uint256 gameId = scrabble.createGame(1e6, address(0), sig1);

        // Player2 deposits & joins
        vm.deal(player2, 1 ether);
        bytes memory sig2 = signAuth(player2, player2Pk);
        vm.prank(player2);
        wallet.depositETH{value: 1 ether}(sig2);

        console.log("Player2 joining game ID:");
        console.log(gameId);
        vm.prank(player2);
        scrabble.joinGame(gameId, 1e6, sig2);

        address secondPlayer = scrabble.getGame(gameId).players[1];
        console.log("Second player in game:");
        console.log(secondPlayer);

        assertEq(secondPlayer, player2, "Second player should be player2");
    }

    function test_SubmitResult() public {
        // Player1 deposits & creates game
        vm.deal(player1, 1 ether);
        bytes memory sig1 = signAuth(player1, player1Pk);
        vm.prank(player1);
        wallet.depositETH{value: 1 ether}(sig1);
        vm.prank(player1);
        uint256 gameId = scrabble.createGame(1e6, address(0), sig1);

        // Submitter submits result
        // uint32 ;
        uint32[] memory scores = new uint32[](1);
        scores[0] = 100;

        console.log("Submitting result for game ID:");
        console.log(gameId);
        vm.prank(submitter);
        scrabble.submitResult(gameId, player1, bytes32(0), scores, 0);

        address winner = scrabble.getGame(gameId).winner;
        console.log("Winner for game ID:");
        console.log(winner);

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
