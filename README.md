# Scrabble On-Chain Game Settlement API

## Overview
This project comprises a suite of Solidity smart contracts designed to facilitate a decentralized Scrabble game platform on the Ethereum blockchain. It includes robust mechanisms for game creation, player participation, stake management, and secure result settlement, leveraging the Foundry development framework, OpenZeppelin for battle-tested components, and Chainlink for real-time price data.

## Features
- Solidity: Core logic for game creation, joining, and settlement.
- Foundry: Comprehensive development environment for testing and deployment.
- OpenZeppelin Contracts: Utilizes standardized contracts for Access Control, Pausability, and Reentrancy Guard.
- Chainlink Price Feeds: Integrates `AggregatorV3Interface` for secure on-chain price conversions (e.g., ETH to USD).
- Role-Based Access Control: Granular permission management for various participant roles including administrators, auditors, and token managers.
- KYC and Blacklisting: On-chain mechanisms for user verification status and exclusion of malicious addresses.
- Multi-Token Staking: Supports staking with native ETH, USDT, and USDC ERC20 tokens for game participation.
- EIP-712 Authentication: Secure off-chain message signing for user authentication with a designated backend signer.
- Centralized Result Submission: A dedicated submitter address is authorized to record final game results on-chain, ensuring integrity.
- Reentrancy Protection: Implements reentrancy guards to secure critical financial operations.

## Getting Started
### Installation
To set up and interact with this project locally, follow these steps:

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/base-scrabble/scrabble-contracts.git
    cd scrabble-contracts
    ```

2.  **Install Foundry**:
    Ensure Foundry is installed. If not, you can install it via:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3.  **Install Dependencies**:
    Fetch all external smart contract libraries (OpenZeppelin, Chainlink, Forge-Std):
    ```bash
    forge install
    ```

4.  **Build Contracts**:
    Compile the smart contracts:
    ```bash
    forge build
    ```

### Environment Variables
The smart contracts require specific addresses for deployment and interaction, typically managed via environment variables in deployment scripts. These are crucial for configuring the contracts correctly on the target blockchain network.

-   `WALLET_CONTRACT_ADDRESS`: The deployed address of the `Wallet` contract.
-   `SUPER_ADMIN_ADDRESS`: The Ethereum address designated as the initial super administrator upon contract deployment.
-   `SUBMITTER_ADDRESS`: The Ethereum address authorized to submit final game results to the `Scrabble` contract.
-   `BACKEND_SIGNER_ADDRESS`: The Ethereum address used by the project's backend service to sign EIP-712 authentication messages for user interactions.
-   `USDT_TOKEN_ADDRESS`: The contract address of the Tether USD (USDT) ERC20 token on the target network.
-   `USDC_TOKEN_ADDRESS`: The contract address of the USD Coin (USDC) ERC20 token on the target network.
-   `ETH_USD_PRICE_FEED_ADDRESS`: The contract address of the Chainlink ETH/USD price feed used for converting ETH values.

_Example environment configuration (e.g., within a `.env` file for deployment):_
```
WALLET_CONTRACT_ADDRESS=0x123...
SUPER_ADMIN_ADDRESS=0xabc...
SUBMITTER_ADDRESS=0xdef...
BACKEND_SIGNER_ADDRESS=0xghi...
USDT_TOKEN_ADDRESS=0x234... # Example: 0xdAC17F958D2ee523a2206206994597C13D831ec7 (Ethereum Mainnet)
USDC_TOKEN_ADDRESS=0x345... # Example: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 (Ethereum Mainnet)
ETH_USD_PRICE_FEED_ADDRESS=0x456... # Example: 0x5f4eC3FbE309394fE9dF42f880DfF76eCc9aF2b9 (Ethereum Mainnet)
```

## API Documentation

The core functionality of the Scrabble On-Chain Game Settlement system is exposed through its smart contract interfaces, primarily the `Scrabble` and `Wallet` contracts. Interactions involve sending transactions or making view calls to these deployed contracts.

### Contract Addresses
- **Scrabble Contract**: `[DeployedScrabbleContractAddress]` (This address is returned by the deployment script, e.g., `DeployScrabble.s.sol`)
- **Wallet Contract**: `[DeployedWalletContractAddress]` (This address is returned by the deployment script, e.g., `DeployScrabble.s.sol`)

### Endpoints (Smart Contract Functions)

#### CALL `Scrabble.createGame(uint256 stakeAmount, address token, bytes calldata backendSig)`
Creates a new Scrabble game instance, initializing it with the creator's stake. The creator's funds are deducted from their associated `Wallet` balance. This function requires an EIP-712 signature from a designated backend signer for authentication.

**Request**:
```json
{
  "stakeAmount": 10000000000000000, // uint256 (e.g., 0.01 ETH in Wei, or 10 USDT in its smallest unit if USDT has 6 decimals, it would be 10 * 10^6)
  "token": "0x0000000000000000000000000000000000000000", // address (Use 0x00...00 for native ETH, or the ERC20 token contract address for USDT/USDC)
  "backendSig": "0x7a83d09a0e6b...0a92f659d" // bytes calldata (EIP-712 signature authorizing msg.sender for this action)
}
```
**Response**:
```json
{
  "gameId": 1 // uint256 (The unique identifier for the newly created game)
}
```
**Events Emitted**:
- `GameCreated(uint256 indexed gameId, address indexed player, address token, uint256 stake)`
**Errors**:
- `Scrabble__UnsupportedToken`: The specified `token` address is not configured as a supported staking token.
- `Scrabble__InsufficientAmountForStake`: The `stakeAmount` is either zero or falls below the predefined minimum stake threshold.
- `Scrabble__InsufficientWalletBalance`: The `msg.sender` (game creator) does not possess sufficient balance in their associated `Wallet` for the required `stakeAmount`.
- `NotAuthenticated`: The provided `backendSig` is invalid or does not correspond to the authorized backend signer, indicating an unauthorized request.
- `System paused`: The `Scrabble` contract is currently in a paused state, preventing new game creation.
- `Blacklisted`: The `msg.sender` address is on the `AccessManager`'s blacklist, prohibiting interaction.
- `Scrabble__WalletInteractionFailed`: An internal error occurred during the fund deduction process by the `Wallet` contract.

#### CALL `Scrabble.joinGame(uint256 gameId, uint256 stakeAmount, bytes calldata backendSig)`
Enables a player to join an existing game specified by `gameId`. The joining player's `stakeAmount` must exactly match the original stake set by the game creator. Funds are deducted from the player's `Wallet`. This function also requires backend authentication.

**Request**:
```json
{
  "gameId": 1, // uint256 (The unique identifier of the game to join)
  "stakeAmount": 10000000000000000, // uint256 (Must exactly match the initial stake defined for the gameId)
  "backendSig": "0x7a83d09a0e6b...0a92f659d" // bytes calldata (EIP-712 signature authorizing msg.sender for this action)
}
```
**Response**:
_No direct return value. The function completes successfully upon execution, updating the game state._
**Events Emitted**:
- `GameJoined(uint256 indexed gameId, address indexed player, uint256 stake)`
**Errors**:
- `Scrabble__InvalidGame`: The `gameId` provided does not correspond to an existing or valid game.
- `Scrabble__AlreadyJoined`: The game has already reached its maximum capacity of players (currently set to 4).
- `Scrabble__InvalidGamePairing`: The `msg.sender` is attempting to join a game they already initiated or are a part of.
- `Scrabble__StakeMisMatch`: The provided `stakeAmount` does not match the `stake` amount set by the game's creator.
- `Scrabble__WalletInteractionFailed`: An internal error occurred during the fund deduction process by the `Wallet` contract.
- `NotAuthenticated`: The provided `backendSig` is invalid or does not correspond to the authorized backend signer.
- `System paused`: The `Scrabble` contract is currently paused.
- `Blacklisted`: The `msg.sender` address is on the `AccessManager`'s blacklist.

#### CALL `Scrabble.submitResult(uint256 gameId, address winner, bytes32 finalBoardHash, uint32[] calldata scores, uint256 roundNumber)`
Submits the final result of a game, including the winner, final board hash, and player scores. This function handles the distribution of the accumulated stake to the winner or refunds in case of a draw. It can only be called by the `i_submitter` address configured during contract deployment.

**Request**:
```json
{
  "gameId": 1, // uint256 (The unique identifier of the game being settled)
  "winner": "0xAbcDef1234567890abcdef1234567890AbcDef", // address (The Ethereum address of the winning player, or 0x00...00 for a draw scenario)
  "finalBoardHash": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b", // bytes32 (A content-addressed hash representing the final state of the game board for verification)
  "scores": [120, 95], // uint32[] (An array of final scores for each player, ordered to correspond with the game.players array)
  "roundNumber": 1 // uint256 (The expected round number for this game, used to prevent stale or out-of-order submissions)
}
```
**Response**:
_No direct return value. The function completes successfully upon execution, settling the game and distributing funds._
**Events Emitted**:
- `GameSettled(uint256 indexed gameId, address indexed winner, uint256 payout, bytes32 finalBoardHash, uint32[] scores)`
**Errors**:
- `Scrabble__InvalidGame`: The `gameId` does not correspond to an existing or valid game.
- `Scrabble__InvalidRound`: The `scores` array length does not match the number of players in the game, or the `roundNumber` provided is not the currently expected round.
- `Scrabble__AlreadySettled`: The game specified by `gameId` has already been settled and funds distributed.
- `Scrabble__InvalidWinner`: The `winner` address provided is not one of the registered players in the game (unless it is `address(0)` for a draw).
- `Scrabble__InvalidSubmitter`: The `msg.sender` is not the authorized `i_submitter` address.
- `System paused`: The `Scrabble` contract is currently paused.
- `Blacklisted`: The `msg.sender` address is on the `AccessManager`'s blacklist.

#### TRANSACTION `Wallet.depositETH(bytes calldata backendSig)`
Allows a user to deposit native Ethereum (ETH) into their internal wallet balance managed by the `Wallet` contract. The amount of ETH sent with the transaction (`msg.value`) must meet a minimum equivalent USD value. Requires backend authentication.

**Request**:
_This is a payable function and requires native ETH to be sent along with the transaction._
```json
{
  "value": 100000000000000000, // uint256 (The amount of ETH in Wei to be deposited, e.g., 0.1 ETH, sent as msg.value)
  "backendSig": "0x7a83d09a0e6b...0a92f659d" // bytes calldata (EIP-712 signature authorizing msg.sender for this action)
}
```
**Response**:
_No direct return value. The function completes successfully upon execution, updating the user's ETH balance._
**Events Emitted**:
- `FundsDeposited(address indexed user, address indexed token, uint256 amount)`
**Errors**:
- `Wallet__InsufficientFundsToDeposit`: The `msg.value` sent (ETH amount) does not meet the minimum deposit requirement when converted to USD.
- `NotAuthenticated`: The provided `backendSig` is invalid or does not correspond to the authorized backend signer.
- `System paused`: The `Wallet` contract is currently paused.
- `Blacklisted`: The `msg.sender` address is on the `AccessManager`'s blacklist.

#### TRANSACTION `Wallet.withdrawETH(uint256 amount, bytes calldata backendSig)`
Enables a user to withdraw a specified `amount` of native ETH from their internal `Wallet` balance to their external address. This operation requires backend authentication.

**Request**:
```json
{
  "amount": 50000000000000000, // uint256 (The amount of ETH in Wei to be withdrawn, e.g., 0.05 ETH)
  "backendSig": "0x7a83d09a0e6b...0a92f659d" // bytes calldata (EIP-712 signature authorizing msg.sender for this action)
}
```
**Response**:
_No direct return value. The function completes successfully upon execution, transferring ETH to the user and updating their balance._
**Events Emitted**:
- `FundsWithdrawn(address indexed user, address indexed token, uint256 amount)`
**Errors**:
- `Wallet__BalanceIsLessThanAmountToWithdraw`: The user's available ETH balance in the `Wallet` is less than the requested `amount` for withdrawal.
- `Wallet__AmountTooSmall`: The withdrawal `amount` is zero.
- `Wallet__TransferFailed`: The internal transfer of ETH from the `Wallet` contract to the `msg.sender`'s address failed.
- `NotAuthenticated`: The provided `backendSig` is invalid or does not correspond to the authorized backend signer.
- `System paused`: The `Wallet` contract is currently paused.
- `Blacklisted`: The `msg.sender` address is on the `AccessManager`'s blacklist.

#### TRANSACTION `Wallet.depositToken(address token, uint256 amount, bytes calldata backendSig)`
Allows a user to deposit supported ERC20 tokens (e.g., USDT, USDC) into their internal wallet balance. Prior to calling this function, the user must have approved the `Wallet` contract to spend the specified `amount` of `token` on their behalf. Requires backend authentication.

**Request**:
```json
{
  "token": "0xdAC17F958D2ee523a2206206994597C13D831ec7", // address (The contract address of the ERC20 token, e.g., USDT or USDC)
  "amount": 100000000, // uint256 (The amount of ERC20 tokens to deposit in their smallest unit, e.g., 10 USDT if USDT has 6 decimals)
  "backendSig": "0x7a83d09a0e6b...0a92f659d" // bytes calldata (EIP-712 signature authorizing msg.sender for this action)
}
```
**Response**:
_No direct return value. The function completes successfully upon execution, updating the user's token balance._
**Events Emitted**:
- `FundsDeposited(address indexed user, address indexed token, uint256 amount)`
**Errors**:
- `Wallet__UnsupportedToken`: The specified ERC20 `token` address is not configured as a supported token for deposits.
- `Wallet__AmountTooSmall`: The deposit `amount` is zero.
- `Wallet__TransferFailed`: The `IERC20(token).transferFrom` call failed, possibly due to insufficient allowance or token balance by `msg.sender`.
- `NotAuthenticated`: The provided `backendSig` is invalid or does not correspond to the authorized backend signer.
- `System paused`: The `Wallet` contract is currently paused.
- `Blacklisted`: The `msg.sender` address is on the `AccessManager`'s blacklist.

#### TRANSACTION `Wallet.withdrawToken(address token, uint256 amount, bytes calldata backendSig)`
Enables a user to withdraw a specified `amount` of supported ERC20 tokens (e.g., USDT, USDC) from their internal `Wallet` balance to their external address. This operation requires backend authentication.

**Request**:
```json
{
  "token": "0xdAC17F958D2ee523a2206206994597C13D831ec7", // address (The contract address of the ERC20 token to withdraw)
  "amount": 50000000, // uint256 (The amount of ERC20 tokens to withdraw in their smallest unit, e.g., 5 USDT if USDT has 6 decimals)
  "backendSig": "0x7a83d09a0e6b...0a92f659d" // bytes calldata (EIP-712 signature authorizing msg.sender for this action)
}
```
**Response**:
_No direct return value. The function completes successfully upon execution, transferring tokens to the user and updating their balance._
**Events Emitted**:
- `FundsWithdrawn(address indexed user, address indexed token, uint256 amount)`
**Errors**:
- `Wallet__UnsupportedToken`: The specified ERC20 `token` address is not configured as a supported token for withdrawals.
- `Wallet__AmountTooSmall`: The withdrawal `amount` is zero.
- `Wallet__BalanceIsLessThanAmountToWithdraw`: The user's available token balance in the `Wallet` is less than the requested `amount` for withdrawal.
- `Wallet__TransferFailed`: The `IERC20(token).transfer` call from the `Wallet` contract to the `msg.sender`'s address failed.
- `NotAuthenticated`: The provided `backendSig` is invalid or does not correspond to the authorized backend signer.
- `System paused`: The `Wallet` contract is currently paused.
- `Blacklisted`: The `msg.sender` address is on the `AccessManager`'s blacklist.

## Usage
After deploying the `Wallet` and `Scrabble` contracts to your target blockchain network and configuring the necessary roles and authorized callers (e.g., setting the `Scrabble` contract as an authorized caller in the `Wallet`), users can interact with the system.

1.  **Depositing Funds**: Players first deposit native ETH or supported ERC20 tokens (USDT, USDC) into their `Wallet` contract balance using the `depositETH` or `depositToken` functions. This typically involves a transaction signed by the user and authenticated by the backend.
2.  **Creating a Game**: A player can initiate a new Scrabble game by calling `Scrabble.createGame`, specifying a `stakeAmount` and `token`. The `stakeAmount` is deducted from their `Wallet` balance and locked for the game.
3.  **Joining a Game**: Other players can join an open game by calling `Scrabble.joinGame` with the matching `gameId` and `stakeAmount`. Their stake is also locked from their `Wallet`.
4.  **Game Progression (Off-chain)**: The actual Scrabble game is played off-chain.
5.  **Submitting Results**: Once the off-chain game concludes, the designated `submitter` (a centralized entity) calls `Scrabble.submitResult`. This function records the `winner`, `finalBoardHash`, and `scores`, then distributes the total pooled `stakeAmount` to the winner or refunds players in case of a draw.

## Technologies Used

| Technology | Category                 | Link                                                               |
| :--------- | :----------------------- | :----------------------------------------------------------------- |
| Solidity   | Smart Contract Language  | [Solidity Lang](https://soliditylang.org/)                         |
| Foundry    | Development Framework    | [Foundry Docs](https://book.getfoundry.sh/)                        |
| OpenZeppelin | Standardized Contracts | [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/) |
| Chainlink  | Decentralized Oracles    | [Chainlink Docs](https://docs.chain.link/)                         |
| ERC-20     | Token Standard           | [Ethereum ERC-20](https://eips.ethereum.org/EIPS/eip-20)           |

## Contributing
We welcome contributions to the Scrabble On-Chain Game Settlement project. To contribute:

-   **Fork the Repository**: Start by forking the `scrabble-contracts` repository to your GitHub account.
-   **Create a New Branch**: For each feature or bug fix, create a new branch from `main` (e.g., `feature/add-new-token` or `fix/reentrancy-bug`).
-   **Implement Changes**: Write your code, ensuring it adheres to the project's coding standards. Include comprehensive tests for your changes.
-   **Run Tests**: Execute `forge test` to ensure all existing tests pass and your new tests are effective.
-   **Submit a Pull Request**: Push your branch to your forked repository and open a pull request against the `main` branch of the original repository. Provide a clear description of your changes and why they are necessary.

## Author Info
- **Adebakin Olujimi**
  - LinkedIn: [Your LinkedIn Profile]
  - Twitter: [Your Twitter Handle]

## License
This project is licensed under the MIT License.

---

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)