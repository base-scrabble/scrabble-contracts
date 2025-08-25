# Base Scrabble Contracts API

## Overview
This project provides a robust suite of Solidity smart contracts designed to power a decentralized Scrabble game ecosystem, managing player wallets, game state, and secure result settlements using EIP-712 signatures, built with Foundry and OpenZeppelin. 🎲

## Features
- **Solidity**: Implements on-chain game mechanics, financial logic, and secure state management for the Scrabble game.
- **Foundry**: Utilized as a comprehensive framework for smart contract development, facilitating efficient building, testing, and deployment.
- **OpenZeppelin Contracts**: Integrates battle-tested libraries for secure access control, pausing mechanisms, and reentrancy protection.
- **Chainlink Price Feeds**: Leverages decentralized oracles for reliable, real-time ETH/USD price conversions within the Wallet contract.
- **EIP-712 Signatures**: Implements structured data hashing and signing to ensure secure off-chain authentication for user actions and authorized game result submissions.
- **AccessManager**: Centralized module providing granular role-based access control, KYC status tracking, address blacklisting, and property-specific permissions.
- **Multi-Token Wallet**: Manages user balances for native ETH, USDT, and USDC, handling deposits, withdrawals, and game staking operations.

## Getting Started
To get started with the Base Scrabble Contracts project locally, follow these step-by-step instructions:

### Installation
- 📥 **Clone the Repository**:
  ```bash
  git clone https://github.com/base-scrabble/scrabble-contracts.git
  cd scrabble-contracts
  ```
- 📦 **Install Foundry**: If you do not have Foundry installed on your system, please follow the official installation guide.
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
- ⚙️ **Install Dependencies**: This command will automatically fetch and initialize the necessary OpenZeppelin and Chainlink submodules as defined in `foundry.toml`.
  ```bash
  forge install
  ```
- 🛠️ **Build Contracts**: Compile the Solidity smart contracts to generate their artifacts.
  ```bash
  forge build
  ```
- 🧪 **Run Tests**: Execute the comprehensive test suite to verify the contracts' functionality and integrity.
  ```bash
  forge test
  ```

### Environment Variables
For successful deployment and interaction with the contracts, the following environment variables or configuration parameters are typically required. These are passed to deployment scripts or configured within your Foundry environment.

- `RPC_URL`: The endpoint URL for your target blockchain network (e.g., Infura, Alchemy URL for Ethereum, Polygon, etc.).
  - Example: `RPC_URL="https://sepolia.infura.io/v3/YOUR_PROJECT_ID"`
- `PRIVATE_KEY`: The private key of the Ethereum account designated to deploy contracts and send transactions. **Caution: Handle this key with extreme security, especially in production environments.**
  - Example: `PRIVATE_KEY="0x...your_deployer_private_key..."`
- `ETHERSCAN_API_KEY`: An API key for Etherscan or a compatible block explorer, used for automated contract verification after deployment.
  - Example: `ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"`
- `CHAINLINK_ETH_USD_PRICE_FEED`: The contract address of the Chainlink ETH/USD price feed (`AggregatorV3Interface`) on your chosen blockchain network.
  - Example: `CHAINLINK_ETH_USD_PRICE_FEED="0x694AA1769357215Ee4EfB405d263a54d217d235E"` (Example for Sepolia Testnet)
- `USDT_TOKEN_ADDRESS`: The ERC20 contract address for the Tether (USDT) token on the target network.
  - Example: `USDT_TOKEN_ADDRESS="0x...usdt_contract_address..."`
- `USDC_TOKEN_ADDRESS`: The ERC20 contract address for the USD Coin (USDC) token on the target network.
  - Example: `USDC_TOKEN_ADDRESS="0x...usdc_contract_address..."`
- `SUPER_ADMIN_ADDRESS`: The initial Ethereum address to be granted the `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE` within the `AccessManager` contract upon deployment.
  - Example: `SUPER_ADMIN_ADDRESS="0x...your_admin_wallet_address..."`
- `BACKEND_SIGNER_ADDRESS`: The Ethereum address of the trusted backend service responsible for generating and signing EIP-712 messages for user authentication.
  - Example: `BACKEND_SIGNER_ADDRESS="0x...your_backend_signing_wallet_address..."`
- `GAME_SUBMITTER_ADDRESS`: The Ethereum address that is authorized to submit final game results to the `Scrabble` contract. This is typically an address controlled by a centralized game server or oracle.
  - Example: `GAME_SUBMITTER_ADDRESS="0x...your_game_submitter_address..."`

## API Documentation
The smart contracts within this project act as a decentralized API. Interactions with these contracts involve sending transactions to invoke state-changing functions or making view calls to retrieve data from the blockchain state.

### Deployed Contract Addresses
- **AccessManager**: `[DeployedAddress]`
- **Wallet**: `[DeployedAddress]`
- **Scrabble**: `[DeployedAddress]`

### Endpoints

#### `TRANSACTION AccessManager.setKYC(address user, bool status)`
Updates the Know Your Customer (KYC) verification status for a specified user.
**Authorization**: Requires the caller to possess the `AUDITOR_ROLE`.
**Request**:
```json
{
  "user": "0xTargetUserAddress", // address, The Ethereum address of the user whose KYC status is to be updated.
  "status": true // bool, Set to `true` to mark as KYC verified, `false` otherwise.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an AUDITOR_ROLE`: The calling address does not have the necessary `AUDITOR_ROLE`.
- `System paused`: The `AccessManager` contract is currently in a paused state.

#### `TRANSACTION AccessManager.blacklist(address user, bool status)`
Adds an address to, or removes an address from, the global blacklist.
**Authorization**: Requires the caller to possess the `ADMIN_ROLE`.
**Request**:
```json
{
  "user": "0xTargetUserAddress", // address, The Ethereum address to be blacklisted or unblacklisted.
  "status": true // bool, Set to `true` to blacklist the address, `false` to remove it from the blacklist.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an ADMIN_ROLE`: The calling address does not have the necessary `ADMIN_ROLE`.
- `System paused`: The `AccessManager` contract is currently in a paused state.

#### `TRANSACTION AccessManager.whitelistIP(bytes32 ipHash, bool status)`
Manages whitelisted IP hashes. This is for off-chain IP verification, where hashes are stored on-chain.
**Authorization**: Requires the caller to possess the `ADMIN_ROLE`.
**Request**:
```json
{
  "ipHash": "0x...IPAddressHash...", // bytes32, The `keccak256` hash of the IP address to manage.
  "status": true // bool, Set to `true` to whitelist the IP hash, `false` to remove it.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an ADMIN_ROLE`: The calling address does not have the necessary `ADMIN_ROLE`.
- `System paused`: The `AccessManager` contract is currently in a paused state.

#### `TRANSACTION AccessManager.setTimeLimitedRole(address user, bytes32 role, uint256 duration)`
Grants a specific role to a user for a limited duration.
**Authorization**: Requires the caller to possess the `ADMIN_ROLE`.
**Request**:
```json
{
  "user": "0xTargetUserAddress", // address, The Ethereum address to which the role will be granted.
  "role": "0x...RoleHash...", // bytes32, The identifier of the role (e.g., `keccak256("REALTOR_ROLE")`).
  "duration": 3600 // uint256, The duration in seconds for which the role will be valid (e.g., 3600 for 1 hour).
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an ADMIN_ROLE`: The calling address does not have the necessary `ADMIN_ROLE`.
- `System paused`: The `AccessManager` contract is currently in a paused state.

#### `TRANSACTION AccessManager.grantPropertyPermission(uint256 propertyId, address user)`
Grants a user specific permission to interact with a particular property.
**Authorization**: Requires the caller to possess the `REALTOR_ROLE`.
**Request**:
```json
{
  "propertyId": 123, // uint256, The unique identifier of the property.
  "user": "0xTargetUserAddress" // address, The Ethereum address to grant permission to for the property.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not a REALTOR_ROLE`: The calling address does not have the necessary `REALTOR_ROLE`.
- `System paused`: The `AccessManager` contract is currently in a paused state.

#### `TRANSACTION AccessManager.revokePropertyPermission(uint256 propertyId, address user)`
Revokes a user's specific permission to interact with a particular property.
**Authorization**: Requires the caller to possess the `REALTOR_ROLE`.
**Request**:
```json
{
  "propertyId": 123, // uint256, The unique identifier of the property.
  "user": "0xTargetUserAddress" // address, The Ethereum address from which permission is to be revoked.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not a REALTOR_ROLE`: The calling address does not have the necessary `REALTOR_ROLE`.
- `System paused`: The `AccessManager` contract is currently in a paused state.

#### `TRANSACTION AccessManager.pause()`
Pauses the contract, disabling certain functionalities that are protected by the `whenNotPaused` modifier.
**Authorization**: Requires the caller to possess the `ADMIN_ROLE`.
**Request**:
_No payload required._
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an ADMIN_ROLE`: The calling address does not have the necessary `ADMIN_ROLE`.
- `Pausable: paused`: The contract is already in a paused state.

#### `TRANSACTION AccessManager.unpause()`
Unpauses the contract, re-enabling functionalities previously disabled by `pause()`.
**Authorization**: Requires the caller to possess the `ADMIN_ROLE`.
**Request**:
_No payload required._
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an ADMIN_ROLE`: The calling address does not have the necessary `ADMIN_ROLE`.
- `Pausable: not paused`: The contract is not currently in a paused state.

#### `VIEW CALL AccessManager.hasAccessToProperty(uint256 propertyId, address user)`
Checks if a specified user has access permissions for a given property.
**Request**:
```json
{
  "propertyId": 123, // uint256, The unique identifier of the property to check.
  "user": "0xUserAddress" // address, The Ethereum address of the user to check.
}
```
**Response**:
```json
{
  "hasAccess": true // bool, `true` if the user has access to the property, `false` otherwise.
}
```
**Errors**:
_None_

#### `VIEW CALL AccessManager.roleValid(address user, bytes32 role)`
Verifies if a user's time-limited role is currently active and has not expired.
**Request**:
```json
{
  "user": "0xUserAddress", // address, The Ethereum address of the user.
  "role": "0x...RoleHash..." // bytes32, The identifier of the role to validate.
}
```
**Response**:
```json
{
  "isValid": true // bool, `true` if the role is valid and unexpired, `false` otherwise.
}
```
**Errors**:
_None_

#### `VIEW CALL AccessManager.hasRoleAndKYC(address user, bytes32 role)`
Performs a comprehensive check: verifies if a user has a specific role, is KYC verified, is not blacklisted, and if the role is currently valid.
**Request**:
```json
{
  "user": "0xUserAddress", // address, The Ethereum address of the user.
  "role": "0x...RoleHash..." // bytes32, The identifier of the role to check.
}
```
**Response**:
```json
{
  "isAuthorized": true // bool, `true` if all conditions (role, KYC, blacklist, role validity) are met, `false` otherwise.
}
```
**Errors**:
_None_

#### `TRANSACTION Wallet.setAuthorizedCaller(address caller, bool authorized)`
Authorizes or de-authorizes an external contract (e.g., the Scrabble game contract) to interact with the Wallet's `deductFunds` and `addWinnings` functions.
**Authorization**: Requires the caller to possess the `ADMIN_ROLE`. Also protected by `whenNotPaused`.
**Request**:
```json
{
  "caller": "0xContractAddress", // address, The contract address to grant or revoke authorization.
  "authorized": true // bool, `true` to authorize, `false` to revoke permissions.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an ADMIN_ROLE`: The calling address does not have the necessary `ADMIN_ROLE`.
- `System paused`: The `Wallet` contract is currently in a paused state.

#### `TRANSACTION Wallet.depositETH(bytes calldata backendSig)` (payable)
Allows a user to deposit native ETH into their personal wallet balance held within this contract.
**Authorization**: Requires `onlyAuthenticated`, `notBlacklisted`, `whenNotPaused`, and `nonReentrant` modifiers to pass. The transaction must also be `payable`.
**Request**:
```json
{
  "value": "100000000000000000", // uint256, The amount of ETH in wei to deposit (e.g., 0.1 ETH).
  "backendSig": "0xSignedAuthMessage" // bytes, An EIP-712 signature generated by the trusted backend signer, authorizing `msg.sender` for this action.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Wallet__InsufficientFundsToDeposit`: The deposited ETH value, when converted to USD, is less than the `MINIMUM_DEPOSIT` threshold.
- `Wallet__NotAuthenticated`: The `backendSig` provided is invalid or was not signed by the designated `i_backendSigner`.
- `System paused`: The `Wallet` contract is currently in a paused state.
- `Blacklisted`: `msg.sender` is listed on the blacklist.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Wallet.withdrawETH(uint256 amount, bytes calldata backendSig)`
Facilitates the withdrawal of native ETH from a user's wallet balance.
**Authorization**: Requires `onlyAuthenticated`, `notBlacklisted`, `whenNotPaused`, and `nonReentrant` modifiers to pass.
**Request**:
```json
{
  "amount": 100000000000000000, // uint256, The amount of ETH in wei to withdraw.
  "backendSig": "0xSignedAuthMessage" // bytes, An EIP-712 signature from the backend, authorizing `msg.sender`.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Wallet__BalanceIsLessThanAmountToWithdraw`: The user's current ETH balance is less than the requested withdrawal amount.
- `Wallet__AmountTooSmall`: The withdrawal `amount` is zero.
- `Wallet__TransferFailed`: The ETH transfer to the user's address failed.
- `Wallet__NotAuthenticated`: The `backendSig` is invalid or not from the `i_backendSigner`.
- `System paused`: The `Wallet` contract is currently in a paused state.
- `Blacklisted`: `msg.sender` is listed on the blacklist.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Wallet.depositToken(address token, uint256 amount, bytes calldata backendSig)`
Allows a user to deposit supported ERC20 tokens (USDT or USDC) into their wallet balance. An `approve` transaction on the ERC20 token contract must precede this call.
**Authorization**: Requires `onlyAuthenticated`, `notBlacklisted`, `whenNotPaused`, and `nonReentrant` modifiers to pass.
**Request**:
```json
{
  "token": "0xTokenAddress", // address, The contract address of the ERC20 token to deposit (must be `USDT` or `USDC`).
  "amount": 1000000, // uint256, The amount of tokens to deposit, in the token's smallest unit (e.g., 1000000 for 1 USDT if it has 6 decimals).
  "backendSig": "0xSignedAuthMessage" // bytes, An EIP-712 signature from the backend, authorizing `msg.sender`.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Wallet__UnsupportedToken`: The provided `token` address is neither `USDT` nor `USDC`.
- `Wallet__AmountTooSmall`: The deposit `amount` is zero.
- `Wallet__TransferFailed`: The `transferFrom` call for the ERC20 token failed (check user's allowance or balance).
- `Wallet__NotAuthenticated`: The `backendSig` is invalid or not from the `i_backendSigner`.
- `System paused`: The `Wallet` contract is currently in a paused state.
- `Blacklisted`: `msg.sender` is listed on the blacklist.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Wallet.withdrawToken(address token, uint256 amount, bytes calldata backendSig)`
Enables a user to withdraw supported ERC20 tokens (USDT or USDC) from their wallet balance.
**Authorization**: Requires `onlyAuthenticated`, `notBlacklisted`, `whenNotPaused`, and `nonReentrant` modifiers to pass.
**Request**:
```json
{
  "token": "0xTokenAddress", // address, The contract address of the ERC20 token to withdraw (must be `USDT` or `USDC`).
  "amount": 1000000, // uint256, The amount of tokens to withdraw, in the token's smallest unit.
  "backendSig": "0xSignedAuthMessage" // bytes, An EIP-712 signature from the backend, authorizing `msg.sender`.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Wallet__UnsupportedToken`: The provided `token` address is neither `USDT` nor `USDC`.
- `Wallet__AmountTooSmall`: The withdrawal `amount` is zero.
- `Wallet__BalanceIsLessThanAmountToWithdraw`: The user's current token balance is less than the requested withdrawal amount.
- `Wallet__TransferFailed`: The `transfer` call for the ERC20 token to the user's address failed.
- `Wallet__NotAuthenticated`: The `backendSig` is invalid or not from the `i_backendSigner`.
- `System paused`: The `Wallet` contract is currently in a paused state.
- `Blacklisted`: `msg.sender` is listed on the blacklist.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Wallet.deductFunds(address user, address token, uint256 amount)`
Deducts a specified amount of funds from a user's balance. This function is designed to be called by authorized game contracts for staking purposes.
**Authorization**: Requires the caller to be an `onlyAuthorizedCaller` and for the contract to be `whenNotPaused`. Also `nonReentrant`.
**Request**:
```json
{
  "user": "0xUserAddress", // address, The Ethereum address of the user whose funds are to be deducted.
  "token": "0xTokenAddress", // address, The token address (`address(0)` for ETH, or `USDT`/`USDC` addresses).
  "amount": 1000000 // uint256, The amount of funds to deduct.
}
```
**Response**:
```json
{
  "success": true // bool, `true` if the deduction was successful, `false` otherwise.
}
```
**Errors**:
- `Wallet__UnsupportedToken`: The provided `token` address is not ETH, USDT, or USDC.
- `Wallet__InsufficientBalanceToStake`: The user's balance for the specified `token` is insufficient.
- `Wallet__NotAuthorized`: The calling contract is not an authorized caller.
- `System paused`: The `Wallet` contract is currently in a paused state.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Wallet.addWinnings(address user, address token, uint256 amount)`
Credits a specified amount of winnings to a user's balance. This function is designed to be called by authorized game contracts for payouts.
**Authorization**: Requires the caller to be an `onlyAuthorizedCaller` and for the contract to be `whenNotPaused`. Also `nonReentrant`.
**Request**:
```json
{
  "user": "0xUserAddress", // address, The Ethereum address to which winnings are to be credited.
  "token": "0xTokenAddress", // address, The token address (`address(0)` for ETH, or `USDT`/`USDC` addresses).
  "amount": 2000000 // uint256, The amount of winnings to credit.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Wallet__UnsupportedToken`: The provided `token` address is not ETH, USDT, or USDC.
- `Wallet__NotAuthorized`: The calling contract is not an authorized caller.
- `System paused`: The `Wallet` contract is currently in a paused state.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `VIEW CALL Wallet.getBalance(address user, address token)`
Retrieves the current balance of a specific token for a given user.
**Request**:
```json
{
  "user": "0xUserAddress", // address, The Ethereum address of the user.
  "token": "0xTokenAddress" // address, The token address (`address(0)` for ETH, or `USDT`/`USDC` addresses).
}
```
**Response**:
```json
{
  "balance": 5000000 // uint256, The user's balance of the specified token.
}
```
**Errors**:
_None_

#### `VIEW CALL Wallet.getMinimumDeposit()`
Returns the minimum required deposit amount, expressed in USD equivalent.
**Request**:
_No payload required._
**Response**:
```json
{
  "minimumDeposit": 100000000 // uint256, The minimum deposit amount (e.g., `1e8` for 1 USD, considering 8 decimals for Chainlink price feeds).
}
```
**Errors**:
_None_

#### `VIEW CALL Wallet.isAuthorizedCaller(address caller)`
Checks if a given address is authorized to invoke game-related functions (`deductFunds`, `addWinnings`) on the Wallet contract.
**Request**:
```json
{
  "caller": "0xContractAddress" // address, The address of the potential caller to check.
}
```
**Response**:
```json
{
  "isAuthorized": true // bool, `true` if the caller is authorized, `false` otherwise.
}
```
**Errors**:
_None_

#### `TRANSACTION Scrabble.createGame(uint256 stakeAmount, address token, bytes calldata backendSig)`
Initiates a new Scrabble game, deducting the specified stake from the creator's wallet.
**Authorization**: Requires `onlyAuthenticated`, `notBlacklisted`, `whenNotPaused`, and `nonReentrant` modifiers to pass.
**Request**:
```json
{
  "stakeAmount": 1000000, // uint256, The amount to be staked per player, in the token's smallest unit (e.g., 1 USDT if 6 decimals).
  "token": "0xTokenAddress", // address, The ERC20 token address to be used for staking (`address(0)` for ETH, or `USDT`/`USDC` addresses).
  "backendSig": "0xSignedAuthMessage" // bytes, An EIP-712 signature from the backend, authorizing `msg.sender` for this game creation.
}
```
**Response**:
```json
{
  "gameId": 12345 // uint256, The unique identifier of the newly created game.
}
```
**Errors**:
- `Scrabble__UnsupportedToken`: The provided `token` address is not supported (only ETH, USDT, USDC).
- `Scrabble__InsufficientAmountForStake`: The `stakeAmount` is below the `MINIMUM_STAKE` or is zero.
- `Scrabble__InsufficientWalletBalance`: The game creator's `Wallet` balance is insufficient for the specified stake.
- `Scrabble__WalletInteractionFailed`: An error occurred during the fund deduction process from the `Wallet` contract.
- `NotAuthenticated`: The `backendSig` is invalid or was not signed by the designated `i_backendSigner`.
- `System paused`: The `Scrabble` contract is currently in a paused state.
- `Blacklisted`: `msg.sender` is listed on the blacklist.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Scrabble.cancelGame(uint256 gameId, bytes calldata backendSig)`
Allows the game creator to cancel a game, provided no other players have joined and the lobby timeout has expired.
**Authorization**: Requires `onlyAuthenticated`, `notBlacklisted`, `whenNotPaused`, and `nonReentrant` modifiers to pass. Only the game creator can call.
**Request**:
```json
{
  "gameId": 12345, // uint256, The unique identifier of the game to be canceled.
  "backendSig": "0xSignedAuthMessage" // bytes, An EIP-712 signature from the backend, authorizing `msg.sender`.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Scrabble__InvalidGame`: The `gameId` is invalid, or `msg.sender` is not the creator of the game.
- `Scrabble__LobbyTimeExpired`: The required lobby timeout period has not yet passed.
- `Scrabble__AlreadyJoined`: Other players have already joined the game, preventing cancellation.
- `Scrabble__AlreadySettled`: The game has already been settled, meaning its funds are no longer locked.
- `NotAuthenticated`: The `backendSig` is invalid or was not signed by the designated `i_backendSigner`.
- `System paused`: The `Scrabble` contract is currently in a paused state.
- `Blacklisted`: `msg.sender` is listed on the blacklist.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Scrabble.joinGame(uint256 gameId, uint256 stakeAmount, bytes calldata backendSig)`
Enables a player to join an existing game, automatically deducting their stake.
**Authorization**: Requires `onlyAuthenticated`, `notBlacklisted`, `whenNotPaused`, and `nonReentrant` modifiers to pass.
**Request**:
```json
{
  "gameId": 12345, // uint256, The unique identifier of the game to join.
  "stakeAmount": 1000000, // uint256, The stake amount the player is committing; must precisely match the creator's stake.
  "backendSig": "0xSignedAuthMessage" // bytes, An EIP-712 signature from the backend, authorizing `msg.sender`.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Scrabble__InvalidGame`: The `gameId` is invalid.
- `Scrabble__AlreadyJoined`: The game is already full (reached `MAX_PLAYER`) or `msg.sender` has already joined.
- `Scrabble__InvalidGamePairing`: `msg.sender` attempted to join their own game.
- `Scrabble__StakeMisMatch`: The `stakeAmount` provided does not match the game's required stake.
- `Scrabble__WalletInteractionFailed`: An error occurred during the fund deduction process from the `Wallet` contract.
- `NotAuthenticated`: The `backendSig` is invalid or was not signed by the designated `i_backendSigner`.
- `System paused`: The `Scrabble` contract is currently in a paused state.
- `Blacklisted`: `msg.sender` is listed on the blacklist.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Scrabble.submitResult(uint256 gameId, address winner, bytes32 finalBoardHash, uint32[] calldata scores, uint256 roundNumber)`
Submits the final result of a game. This function is designed for a centralized `i_submitter` to ensure game integrity.
**Authorization**: Requires the caller to be the `onlySubmitter` and for the contract to be `whenNotPaused` and `nonReentrant`.
**Request**:
```json
{
  "gameId": 12345, // uint256, The unique identifier of the game for which results are being submitted.
  "winner": "0xWinnerAddress", // address, The Ethereum address of the winning player (`0x00...00` for a draw).
  "finalBoardHash": "0x...FinalBoardStateHash...", // bytes32, A content-addressed hash of the final state of the Scrabble board for off-chain verification.
  "scores": [150, 120], // uint32[], An array of player scores; the order must correspond to the `game.players` array.
  "roundNumber": 1 // uint256, The expected round number for this game; must match `s_expectedRound[gameId]` to prevent stale submissions.
}
```
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `Scrabble__InvalidGame`: The `gameId` is invalid.
- `Scrabble__InvalidRound`: The length of the `scores` array does not match the number of players, or `roundNumber` does not match `s_expectedRound[gameId]`.
- `Scrabble__AlreadySettled`: The game has already been settled, meaning its funds are no longer locked.
- `Scrabble__InvalidWinner`: The `winner` address is not one of the game's players (unless it's `address(0)` for a draw).
- `Scrabble__WalletInteractionFailed`: An error occurred during the fund payout process via the `Wallet` contract.
- `Scrabble__InvalidSubmitter`: `msg.sender` is not the designated `i_submitter` address.
- `System paused`: The `Scrabble` contract is currently in a paused state.
- `ReentrancyGuard: reentrant call`: A reentrant call attempt was detected and blocked.

#### `TRANSACTION Scrabble.emergencyPause()`
Invokes an emergency pause on the Scrabble contract, inheriting functionality from OpenZeppelin's `Pausable` contract.
**Authorization**: Requires the caller to possess the `ADMIN_ROLE`.
**Request**:
_No payload required._
**Response**:
_No explicit return value for this transaction._
**Errors**:
- `AccessControl: sender is not an ADMIN_ROLE`: The calling address does not have the necessary `ADMIN_ROLE`.
- `Pausable: paused`: The contract is already in a paused state.

#### `VIEW CALL Scrabble.getGame(uint256 gameId)`
Retrieves the complete game state struct for a given game ID.
**Request**:
```json
{
  "gameId": 12345 // uint256, The unique identifier of the game to retrieve.
}
```
**Response**:
```json
{
  "players": ["0xPlayer1Address", "0xPlayer2Address"], // address[], An array of Ethereum addresses of the players in the game.
  "stake": 1000000, // uint256, The stake amount per player for this game.
  "token": "0xTokenAddress", // address, The token contract address used for staking in this game.
  "fundsLocked": true, // bool, `true` if game funds are currently locked, `false` if settled or cancelled.
  "winner": "0xWinnerAddress", // address, The Ethereum address of the winning player (`0x00...00` for a draw).
  "scores": [150, 120], // uint32[], An array of scores corresponding to the players array.
  "finalBoardHash": "0x...FinalBoardStateHash..." // bytes32, The content-addressed hash of the final game board.
}
```
**Errors**:
_None_

#### `VIEW CALL Scrabble.GameId()`
Returns the current value of the internal game ID counter, representing the last assigned game ID.
**Request**:
_No payload required._
**Response**:
```json
{
  "gameId": 12345 // uint256, The current value of the game ID counter.
}
```
**Errors**:
_None_

#### `VIEW CALL Scrabble.nextGameId()`
Returns the next available game ID that will be assigned when a new game is created.
**Request**:
_No payload required._
**Response**:
```json
{
  "nextId": 12346 // uint256, The calculated next game ID (`s_gameCounter + 1`).
}
```
**Errors**:
_None_

---

## Usage
Interacting with the Base Scrabble Contracts primarily involves sending transactions to the deployed contract addresses on the Ethereum Virtual Machine (EVM) compatible blockchain. For a seamless user experience, a DApp frontend or a dedicated backend service typically handles these interactions on behalf of users.

### Typical Interaction Flow:
1.  **Fund Wallet**: Users typically begin by depositing native ETH or supported ERC20 tokens (USDT, USDC) into their personal balance held by the `Wallet` contract. These deposit actions require an EIP-712 signature from a trusted backend signer to ensure that only authenticated user requests are processed.
2.  **Create Game**: A player can initiate a new Scrabble game by calling `Scrabble.createGame()`, specifying a stake amount and the desired token. The `Scrabble` contract, having been authorized, then interacts with the `Wallet` contract to deduct the stake from the player's balance. This step also requires a backend signature for player authentication.
3.  **Join Game**: Other players can join an existing game by calling `Scrabble.joinGame()`, ensuring their stake amount exactly matches that of the game creator. Similar to game creation, funds are deducted via the `Wallet` contract, and backend authentication is required.
4.  **Game Settlement**: Once a game concludes off-chain (after players have completed their turns and agreed upon a result), an authorized game submitter (usually a centralized backend service or oracle) calls `Scrabble.submitResult()`. This function validates the outcome, updates player scores, and securely credits the total prize pot to the winner's `Wallet` balance (or refunds all players in the event of a draw).
5.  **Withdraw Funds**: Users can at any time withdraw their ETH or ERC20 tokens from the `Wallet` contract back to their external blockchain address by calling `Wallet.withdrawETH()` or `Wallet.withdrawToken()`, with each withdrawal also requiring a backend signature for authentication.

### Example Interaction (Conceptual using `ethers.js`):
The following conceptual code snippets illustrate how a DApp or backend might interact with the contracts.
(Note: Replace placeholders like `WALLET_ABI`, `SCRABBLE_ABI`, `USDT_TOKEN_ADDRESS`, etc., with actual values.)

**1. Approve USDT for Wallet (required before ERC20 deposit):**
Before a user can `depositToken`, they must first grant the `Wallet` contract an allowance to spend their USDT tokens by calling `approve` on the USDT ERC20 contract.
```javascript
import { ethers } from "ethers";

// Assume provider and signer are initialized
const provider = new ethers.JsonRpcProvider("YOUR_RPC_URL");
const signer = new ethers.Wallet("YOUR_PRIVATE_KEY", provider); // User's wallet

const USDT_TOKEN_ADDRESS = "0x...deployed_usdt_address...";
const WALLET_CONTRACT_ADDRESS = "0x...deployed_wallet_address...";
const ERC20_ABI = ["function approve(address spender, uint256 amount) returns (bool)"];

const usdtContract = new ethers.Contract(USDT_TOKEN_ADDRESS, ERC20_ABI, signer);
const amountToApprove = ethers.parseUnits("100", 6); // Example: 100 USDT with 6 decimals

console.log("Approving Wallet to spend USDT...");
const tx = await usdtContract.approve(WALLET_CONTRACT_ADDRESS, amountToApprove);
await tx.wait();
console.log("Approval successful:", tx.hash);
```

**2. Deposit USDT to Wallet (requires backend signature):**
The backend service would generate an EIP-712 signature (`backendSig`) for `msg.sender` (the user performing the deposit).
```javascript
// This part conceptually shows the backend's role in signing.
// In a real application, the backend would expose an API endpoint for this.
async function getBackendSignature(userAddress, verifyingContractAddress, backendSignerPrivateKey) {
    const domain = {
        name: "Wallet",
        version: "1",
        chainId: 11155111, // Example: Sepolia Chain ID
        verifyingContract: verifyingContractAddress,
    };
    const types = {
        Auth: [{ name: "player", type: "address" }],
    };
    const value = {
        player: userAddress,
    };

    const backendSigner = new ethers.Wallet(backendSignerPrivateKey);
    const signature = await backendSigner.signTypedData(domain, types, value);
    return signature;
}

// Frontend (or direct contract interaction)
const WALLET_ABI = ["function depositToken(address token, uint256 amount, bytes calldata backendSig)"]; // Simplified ABI
const userAddress = signer.address;
const amountToDeposit = ethers.parseUnits("50", 6); // 50 USDT

// Assume backend_signer_private_key is securely available on the backend
const backendSig = await getBackendSignature(userAddress, WALLET_CONTRACT_ADDRESS, "0x...backend_signer_private_key...");

const walletContract = new ethers.Contract(WALLET_CONTRACT_ADDRESS, WALLET_ABI, signer);
console.log("Depositing USDT to Wallet...");
const depositTx = await walletContract.depositToken(USDT_TOKEN_ADDRESS, amountToDeposit, backendSig);
await depositTx.wait();
console.log("Deposit successful:", depositTx.hash);
```

**3. Create a Scrabble Game (requires backend signature):**
Similarly, a backend signature is required for a user to create a game.
```javascript
const SCRABBLE_CONTRACT_ADDRESS = "0x...deployed_scrabble_address...";
const SCRABBLE_ABI = ["function createGame(uint256 stakeAmount, address token, bytes calldata backendSig) returns (uint256)"]; // Simplified ABI

const scrabbleContract = new ethers.Contract(SCRABBLE_CONTRACT_ADDRESS, SCRABBLE_ABI, signer);

const stake = ethers.parseUnits("10", 6); // 10 USDT stake for the game

// Reuse the Auth signature type, adjusted for Scrabble contract context
async function getGameBackendSignature(userAddress, verifyingContractAddress, backendSignerPrivateKey) {
    const domain = {
        name: "Scrabble", // Contract name for EIP-712 domain
        version: "1",
        chainId: 11155111, // Example: Sepolia Chain ID
        verifyingContract: verifyingContractAddress,
    };
    const types = {
        Auth: [{ name: "player", type: "address" }],
    };
    const value = {
        player: userAddress,
    };
    const backendSigner = new ethers.Wallet(backendSignerPrivateKey);
    const signature = await backendSigner.signTypedData(domain, types, value);
    return signature;
}

const gameBackendSig = await getGameBackendSignature(userAddress, SCRABBLE_CONTRACT_ADDRESS, "0x...backend_signer_private_key...");

console.log("Creating Scrabble game...");
const createGameTx = await scrabbleContract.createGame(stake, USDT_TOKEN_ADDRESS, gameBackendSig);
const receipt = await createGameTx.wait();
console.log("Game created. Transaction hash:", receipt.hash);
// Parse event to get gameId if needed
```

## Technologies Used

| Technology         | Category         | Description                                                       | Link                                                            |
| :----------------- | :--------------- | :---------------------------------------------------------------- | :-------------------------------------------------------------- |
| **Solidity**       | Language         | The primary language for writing smart contracts on the EVM.      | [Solidity Documentation](https://docs.soliditylang.org/en/latest/) |
| **Foundry**        | Development Tool | A blazing fast, portable, and modular toolkit for EVM development. | [Foundry Book](https://book.getfoundry.sh/)                     |
| **OpenZeppelin**   | Smart Contracts  | A library of battle-tested smart contracts for secure development. | [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/) |
| **Chainlink**      | Oracle Network   | Provides reliable data feeds and decentralized services to smart contracts. | [Chainlink Docs](https://docs.chain.link/data-feeds/)             |
| **EIP-712**        | Ethereum Standard | A standard for hashing and signing typed structured data.         | [EIP-712 Specification](https://eips.ethereum.org/EIPS/eip-712) |
| **USDT (Tether)**  | ERC20 Token      | A widely used stablecoin pegged to the US Dollar.                 | [Tether Official](https://tether.to/)                           |
| **USDC (USD Coin)**| ERC20 Token      | A stablecoin backed by fully reserved assets.                     | [USDC Official](https://www.centre.io/usdc)                     |

## Contributing
We welcome contributions to the Base Scrabble Contracts project! To contribute effectively, please follow these guidelines:

- ✨ **Fork the Repository**: Begin by forking the `scrabble-contracts` repository to your personal GitHub account.
- 🌳 **Create a Feature Branch**: For new features or bug fixes, create a dedicated branch from `main`: `git checkout -b feature/your-feature-name`.
- 💻 **Develop and Test**: Implement your changes and thoroughly test them. Ensure all existing tests pass, and add new tests for any new functionality introduced.
- 📝 **Write Clear Commit Messages**: Craft descriptive commit messages that explain the purpose and scope of your changes. Following conventional commits is encouraged.
- 🚀 **Submit a Pull Request**: Once your changes are complete and tested, open a pull request to the `main` branch. Provide a detailed explanation of your contributions and the problem they solve.

## License
This project does not currently include a `LICENSE` file. For licensing information, please contact the author directly.

## Author Info
- **Adebakin Olujimi**
  - LinkedIn: [Adebakin Olujimi's LinkedIn](https://linkedin.com/in/adebakin-olujimi)
  - Twitter: [Adebakin Olujimi's Twitter](https://twitter.com/YourTwitterHandle)

## Badges
[![Solidity Version](https://img.shields.io/badge/Solidity-^0.8.20-blue)](https://docs.soliditylang.org/en/latest/)
[![Built With Foundry](https://img.shields.io/badge/Built%20With-Foundry-black)](https://book.getfoundry.sh/)
[![License: Unspecified](https://img.shields.io/badge/License-Unspecified-lightgrey)](https://choosealicense.com/)
[![Powered By OpenZeppelin](https://img.shields.io/badge/Powered%20By-OpenZeppelin-2c364e)](https://openzeppelin.com/contracts/)

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)