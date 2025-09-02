// pragma solidity ^0.8.24;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import "../src/wallet/Wallet.sol";
// import "../src/scrabble-game/Scrabble.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract WalletUnitTest is Test {
//     Wallet wallet;

//     Scrabble scrabble;
//     address superAdmin;
//     address user;

//     address superAdmin = address(0x100);
//     address user = address(0x200);
//     address priceFeed = address(0x300);
//     address usdt = address(0x400);
//     address usdc = address(0x500);

//     uint256 backendPk = 0xBEEF;
//     address backendSigner = vm.addr(backendPk);
//     address wrongSigner = address(0x7);

//     mapping(address => uint256) privateKeys;

//     function setUp() public {
//         vm.etch(priceFeed, bytes("mock"));
//         vm.mockCall(
//             priceFeed,
//             abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
//             abi.encode(0, 2000e8, 0, 0, 0)
//         );

//         vm.etch(usdt, bytes("mock"));
//         vm.etch(usdc, bytes("mock"));

//         wallet = new Wallet(priceFeed, superAdmin, usdt, backendSigner, usdc);

//         privateKeys[backendSigner] = backendPk;
//         privateKeys[wrongSigner] = 0xBADBEEF;

//         console.log("Wallet deployed at", address(wallet));
//         superAdmin = makeAddr("superAdmin");
//         user = makeAddr("user");
//         vm.deal(user, 1 ether);
//     }

//     /// -------------------------
//     /// Helper: sign EIP-712 auth
//     /// -------------------------
// function signAuth(address player, address signer) internal view returns (bytes memory) {
//     uint256 pk = privateKeys[signer];
//     uint256 nonce = wallet.getNonce(player);

//     // Split logs to avoid multiple types in one call
//     console.log("Signing auth");

//     console.log("Player:");
//     console.logAddress(player);

//     console.log("Signer:");
//     console.logAddress(signer);

//     console.log("Nonce:");
//     console.logUint(nonce);

//     // Compute the digest
//     bytes32 structHash = keccak256(abi.encode(wallet._AUTH_TYPEHASH(), player, nonce));
//     bytes32 digest = wallet.getDigest(structHash);

//     console.log("StructHash:");
//     console.logBytes32(structHash);

//     console.log("Digest:");
//     console.logBytes32(digest);

//     // Signing
//     (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);

//     console.log("Signature component v:");
//     console.logUint(v);

//     console.log("Signature component r:");
//     console.logBytes32(r);

//     console.log("Signature component s:");
//     console.logBytes32(s);

//     return abi.encodePacked(r, s, v);
// }

//     /// -------------------------
//     /// Positive tests
//     /// -------------------------
//     function test_DepositETH() public {

//         bytes memory sig = signAuth(user, backendSigner);

//         vm.deal(user, 1 ether);
//         bytes memory sig = signAuth(user, backendSigner);

//         vm.prank(user);
//         wallet.depositETH{value: 1 ether}(sig);
//         console.log("DepositETH executed. User balance:", wallet.getBalance(user, address(0)));
//         assertEq(wallet.getBalance(user, address(0)), 1 ether);
//     }

//     function test_WithdrawETH() public {
//         vm.deal(user, 1 ether);
//         bytes memory depositSig = signAuth(user, backendSigner);
//         vm.prank(user);
//         wallet.depositETH{value: 1 ether}(depositSig);

//         bytes memory withdrawSig = signAuth(user, backendSigner);
//         vm.prank(user);
//         wallet.withdrawETH(0.5 ether, withdrawSig);
//         console.log("WithdrawETH executed. User balance:", wallet.getBalance(user, address(0)));
//         assertEq(wallet.getBalance(user, address(0)), 0.5 ether);
//     }

//     function test_DepositToken() public {
//         vm.mockCall(usdt, abi.encodeWithSelector(IERC20.transferFrom.selector), abi.encode(true));
//         bytes memory sig = signAuth(user, backendSigner);
//         vm.prank(user);
//         wallet.depositToken(usdt, 100e6, sig);
//         console.log("DepositToken executed. User USDT balance:", wallet.getBalance(user, usdt));
//         assertEq(wallet.getBalance(user, usdt), 100e6);
//     }

//     function test_SetAuthorizedCaller() public {
//         vm.prank(superAdmin);
//         wallet.setAuthorizedCaller(address(0x7), true);
//         console.log("Authorized caller set. Address:", address(0x7));
//         assertTrue(wallet.isAuthorizedCaller(address(0x7)));
//     }

//     /// @notice Generates EIP-712 signature for authentication
//     /// @param player Address of the player to sign for
//     /// @param signer Address of the backend signer
//     /// @return Signature bytes for authentication
//     function signAuth(address player, address signer) internal view returns (bytes memory) {
//         bytes32 structHash = keccak256(abi.encode(keccak256("Auth(address player)"), player));
//         bytes32 digest = scrabble.getDigest(structHash);
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
//         console.log("Generated signature for player:", player);
//         return abi.encodePacked(r, s, v);
//     /// -------------------------
//     /// Negative tests
//     /// -------------------------
//     function test_RevertWhen_WrongSignerWithdrawETH() public {
//         vm.deal(user, 1 ether);
//         bytes memory sig = signAuth(user, wrongSigner);
//         vm.prank(user);
//         console.log("Attempt withdrawETH with wrong signer");
//         vm.expectRevert(Wallet.Wallet__NotAuthenticated.selector);
//         wallet.withdrawETH(0.5 ether, sig);

//     }

//     function test_RevertWhen_WithdrawMoreThanBalance() public {
//         vm.deal(user, 1 ether);
//         bytes memory depositSig = signAuth(user, backendSigner);
//         vm.prank(user);
//         wallet.depositETH{value: 1 ether}(depositSig);

//         bytes memory withdrawSig = signAuth(user, backendSigner);
//         vm.prank(user);
//         console.log("Attempt withdraw more than balance");
//         vm.expectRevert(Wallet.Wallet__BalanceIsLessThanAmountToWithdraw.selector);
//         wallet.withdrawETH(2 ether, withdrawSig);
//     }

//     function test_RevertWhen_WithdrawZeroETH() public {
//         vm.deal(user, 1 ether);
//         bytes memory sig = signAuth(user, backendSigner);
//         vm.prank(user);
//         console.log("Attempt withdraw 0 ETH");
//         vm.expectRevert(Wallet.Wallet__AmountTooSmall.selector);
//         wallet.withdrawETH(0, sig);
//     }

//     function test_RevertWhen_UnauthorizedSetAuthorizedCaller() public {
//         vm.prank(user);
//         console.log("Attempt unauthorized setAuthorizedCaller");
//         vm.expectRevert(
//             abi.encodeWithSignature(
//                 "AccessControlUnauthorizedAccount(address,bytes32)",
//                 user,
//                 keccak256("ADMIN_ROLE")
//             )
//         );
//         wallet.setAuthorizedCaller(address(0x8), true);
//     }

//     function test_RevertWhen_ReplaySignature() public {
//         vm.deal(user, 1 ether);

//         bytes memory depositSig = signAuth(user, backendSigner);
//         vm.prank(user);
//         wallet.depositETH{value: 1 ether}(depositSig);

//         bytes memory withdrawSig1 = signAuth(user, backendSigner);
//         vm.prank(user);
//         wallet.withdrawETH(0.5 ether, withdrawSig1);

//         console.log("Attempt replay of same signature");
//         vm.prank(user);
//         vm.expectRevert(Wallet.Wallet__NotAuthenticated.selector);
//         wallet.withdrawETH(0.1 ether, withdrawSig1);
//     }

//     function test_RevertWhen_DepositZeroETH() public {
//         bytes memory sig = signAuth(user, backendSigner);
//         vm.prank(user);
//         console.log("Attempt deposit 0 ETH");
//         vm.expectRevert(Wallet.Wallet__InsufficientFundsToDeposit.selector);
//         wallet.depositETH{value: 0}(sig);
//     }
// }
// }
