# Base Scrabble Contracts: Decentralized Game Logic 🎲

## Overview
This project delivers the core smart contract logic for a decentralized Scrabble game, enabling secure game creation, player joining, and fair result settlement on the blockchain. Built with Solidity and Foundry, it incorporates robust access control, an on-chain wallet system, and reentrancy protection.

## Features
*   **Decentralized Game Lifecycle**: Manages the full flow of Scrabble games, from creation and player joining to cancellation and final settlement.
*   **Secure Game Settlement**: Utilizes EIP-712 typed data signatures for off-chain result signing, ensuring authenticity and preventing tampering before on-chain submission.
*   **On-chain Wallet System**: Provides a dedicated `Wallet` contract for players to deposit, withdraw, and stake funds securely for game participation.
*   **Robust Access Control**: Implements granular role-based access management using OpenZeppelin's `AccessControl` for admins, auditors, realtors, and token managers.
*   **KYC & Blacklisting**: Features integrated KYC verification, address blacklisting, and IP whitelisting for enhanced compliance and security.
*   **Pausable Contract State**: Allows administrators to pause contract functionality in emergencies, providing a critical circuit breaker mechanism.
*   **Reentrancy Protection**: Guards critical functions against reentrancy attacks using OpenZeppelin's `ReentrancyGuard`.
*   **Price Conversion**: Integrates Chainlink's `AggregatorV3Interface` to potentially facilitate real-time fiat-to-crypto price conversions for stake amounts (though currently commented out in the `Wallet` deposit logic).

## Getting Started

To get a copy of the project up and running on your local machine for development and testing purposes, follow these steps.

### Installation
🚀 To set up this project, you'll need [Foundry](https://getfoundry.sh/) installed. If you don't have it, you can install it using `foundryup`.

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/base-scrabble/scrabble-contracts.git
    cd scrabble-contracts
    ```

2.  **Install Foundry (if not already installed)**:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3.  **Install Dependencies**:
    The project uses Git submodules for external libraries like OpenZeppelin and Chainlink.
    ```bash
    forge update
    ```

4.  **Build the Project**:
    Compile the smart contracts.
    ```bash
    forge build
    ```

### Environment Variables
For deploying and interacting with the contracts, you will need to specify certain addresses. These are typically set as environment variables or passed directly to deployment scripts.

*   `WALLET_ADDRESS`: Address of the deployed `Wallet` contract. (Required for `Scrabble` constructor)
*   `SUPER_ADMIN_ADDRESS`: Address of the initial admin for `AccessManager`.
*   `SUBMITTER_ADDRESS`: Address authorized to call `submitResult` on the `Scrabble` contract.
*   `BACKEND_SIGNER_ADDRESS`: Address of the EOA used by your backend to sign authentication messages for `createGame` and `joinGame`.

## Usage
This section outlines how to interact with the deployed smart contracts. All interactions are via blockchain transactions.

### Deployment
The `script/DeployScrabble.s.sol` file (though currently commented out) provides an example of how the `Wallet` and `Scrabble` contracts would be deployed. A typical deployment involves:

1.  Deploying the `Wallet` contract.
2.  Deploying the `Scrabble` contract, passing the `Wallet`'s address and the necessary admin/signer addresses to its constructor.

Example (conceptual, based on commented script):
```solidity
// In a deployment script (e.g., DeployScrabble.s.sol)
Wallet wallet = new Wallet(); // Deploy the Wallet first
Scrabble scrabble = new Scrabble(
    address(wallet),
    _superAdminAddress,    // Your designated super admin
    _submitterAddress,     // Your designated submitter for game results
    _backendSignerAddress  // Your backend's EIP-712 signer
);
```

### Core Contract Functions

#### `Wallet.sol` Interactions
The `Wallet` contract manages player funds.

*   **Deposit Funds**:
    Players can deposit native currency (e.g., ETH on Ethereum, BNB on BSC) into their on-chain wallet.
    ```solidity
    function deposit() external payable nonReentrant
    ```
    To deposit 0.01 ETH: `walletContract.deposit{value: 0.01 ether}()`
    _Errors:_ `Wallet__InsuffiecientFundsToDeposit()` (if less than `MINIMUM_DEPOSIT`), transaction reverts.

*   **Withdraw Funds**:
    Players can withdraw their accumulated balance from the wallet.
    ```solidity
    function withdraw(uint256 amount) external nonReentrant
    ```
    _Example:_ `walletContract.withdraw(1e18)` to withdraw 1 ETH.
    _Errors:_ `Wallet__BalanceIsLessThanAmountToWithdraw()`, `Wallet__AmountTooSmall()`, `GameWallet__TransferFailed()`.

*   **Get Balance**:
    Check the balance of any user in the wallet.
    ```solidity
    function getBalance(address user) external view returns (uint256)
    ```

#### `Scrabble.sol` (Game) Interactions
The `Scrabble` contract orchestrates the game logic. Authentication (`onlyAuthenticated`) using `i_backendSigner` is required for `createGame` and `joinGame`. The `submitResult` function requires a `onlySubmitter` role.

*   **Create a Game**:
    A player initiates a new game by staking an amount.
    ```solidity
    function createGame(uint256 stakeAmount, bytes calldata backendSig) external returns (uint256 gameId)
    ```
    _Parameters:_
    *   `stakeAmount`: The amount (in Wei) each player must stake.
    *   `backendSig`: An EIP-712 signature from `i_backendSigner` authorizing `msg.sender` for this action.
    _Errors:_ `Scrabble__InsufficientAmountForStake()`, `Scrabble__InsufficientWalletBalance()`, `Scrabble__WalletInteractionFailed()`, `NotAuthenticated()`.

*   **Join a Game**:
    Another player joins an existing game, matching the creator's stake.
    ```solidity
    function joinGame(uint256 gameId, uint256 stakeAmount, bytes calldata backendSig) external
    ```
    _Parameters:_
    *   `gameId`: The ID of the game to join.
    *   `stakeAmount`: The stake amount, must match the game's initial stake.
    *   `backendSig`: An EIP-712 signature from `i_backendSigner` authorizing `msg.sender`.
    _Errors:_ `Scrabble__InvalidGame()`, `Scrabble__AlreadyJoined()`, `Scrabble__InvalidGamePairing()`, `Scrabble__StakeMisMatch()`, `Scrabble__WalletInteractionFailed()`, `NotAuthenticated()`.

*   **Cancel a Game**:
    The game creator can cancel if no one has joined within the `LOBBY_TIMEOUT`.
    ```solidity
    function cancelGame(uint256 gameId, bytes calldata backendSig) external
    ```
    _Parameters:_
    *   `gameId`: The ID of the game to cancel.
    *   `backendSig`: An EIP-712 signature from `i_backendSigner` authorizing `msg.sender`.
    _Errors:_ `Scrabble__InvalidGame()`, `Scrabble__LobbyTimeExpired()`, `Scrabble__AlreadyJoined()`, `Scrabble__AlreadySettled()`, `NotAuthenticated()`.

*   **Submit Game Result**:
    The designated `i_submitter` (e.g., a centralized backend) submits the final game outcome.
    ```solidity
    function submitResult(
        uint256 gameId,
        address winner,
        bytes32 finalBoardHash,
        uint32[] calldata scores,
        uint256 roundNumber
    ) external
    ```
    _Parameters:_
    *   `gameId`: The ID of the game.
    *   `winner`: Address of the winner (address(0) for a draw).
    *   `finalBoardHash`: A content-addressed hash of the final game board for verification.
    *   `scores`: Array of scores for each player, matching the order in `Game.players`.
    *   `roundNumber`: The expected round number for the game (prevents stale submissions).
    _Errors:_ `Scrabble__InvalidSubmitter()`, `Scrabble__InvalidGame()`, `Scrabble__InvalidRound()`, `Scrabble__AlreadySettled()`, `Scrabble__InvalidWinner()`.

*   **Get Game Data**:
    Retrieve the full details of a specific game.
    ```solidity
    function getGame(uint256 gameId) external view returns (Game memory)
    ```

#### `AccessManager.sol` Interactions
The `AccessManager` contract handles roles, permissions, and security flags.

*   **Assign Roles**:
    Admins can grant specific roles (e.g., `AUDITOR_ROLE`, `REALTOR_ROLE`).
    ```solidity
    function grantRole(bytes32 role, address account) external virtual onlyRole(DEFAULT_ADMIN_ROLE)
    ```
    _Roles Defined:_ `ADMIN_ROLE`, `REALTOR_ROLE`, `INVESTOR_ROLE`, `TENANT_ROLE`, `AUDITOR_ROLE`, `TOKEN_ADMIN_ROLE`.

*   **Set KYC Status**:
    Auditors can verify or unverify a user's KYC status.
    ```solidity
    function setKYC(address user, bool status) external onlyRole(AUDITOR_ROLE)
    ```

*   **Blacklist Users**:
    Admins can blacklist users, preventing them from interacting with certain functions.
    ```solidity
    function blacklist(address user, bool status) external onlyRole(ADMIN_ROLE)
    ```

*   **Pause/Unpause**:
    Admins can pause or unpause contract interactions.
    ```solidity
    function pause() external onlyRole(ADMIN_ROLE)
    function unpause() external onlyRole(ADMIN_ROLE)
    ```

### Custom Errors
The contracts define specific custom errors for clearer debugging and handling:
*   `Scrabble__WalletInteractionFailed()`
*   `Scrabble__InsufficientAmountForStake()`
*   `Scrabble__InsufficientWalletBalance()`
*   `Scrabble__StakeMisMatch()`
*   `Scrabble__InvalidGame()`
*   `Scrabble__AlreadyJoined()`
*   `Scrabble__InvalidWinner()`
*   `Scrabble__InvalidSignature()`
*   `Scrabble__AlreadySettled()`
*   `Scrabble__InvalidSigner()`
*   `Scrabble__InvalidGamePairing()`
*   `Scrabble__InvalidRound()`
*   `Scrabble__LobbyTimeExpired()`
*   `Scrabble__InvalidSubmitter()`
*   `NotAuthenticated()`
*   `Wallet__InsuffiecientFundsToDeposit()`
*   `Wallet__BalanceIsLessThanAmountToWithdraw()`
*   `Wallet__AmountTooSmall()`
*   `GameWallet__TransferFailed()`
*   `Wallet__InsufficientBalanceToStake()`

## Technologies Used
| Technology         | Description                                        | Link                                                                      |
| :----------------- | :------------------------------------------------- | :------------------------------------------------------------------------ |
| **Solidity**       | Smart contract programming language                | [Solidity Docs](https://docs.soliditylang.org/)                           |
| **Foundry**        | Fast, customizable, and portable Ethereum development framework | [Foundry Book](https://book.getfoundry.sh/)                               |
| **OpenZeppelin**   | Libraries of battle-tested smart contracts         | [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts/4.x/)         |
| **Chainlink**      | Decentralized oracle network for real-world data   | [Chainlink Docs](https://docs.chain.link/data-feeds/)                     |

## Contributing
We welcome contributions to the Base Scrabble Contracts! If you're looking to help improve the project, please follow these guidelines:

*   **Fork the repository**.
*   **Create a new branch** for your feature or bug fix.
*   **Implement your changes**, ensuring that your code adheres to existing coding standards.
*   **Write clear and concise commit messages**.
*   **Run tests** (`forge test`) to ensure everything is working as expected and add new tests for your changes.
*   **Open a Pull Request** with a detailed description of your changes.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author
*   **Adebakin Olujimi**
    *   LinkedIn: [Your LinkedIn Profile] (Please replace)
    *   Twitter: [@YourTwitterHandle] (Please replace)

---
![Solidity](https://img.shields.io/badge/Solidity-^0.8.24-lightgrey)
![Foundry](https://img.shields.io/badge/Developed%20with-Foundry-red)
![OpenZeppelin](https://img.shields.io/badge/Powered%20by-OpenZeppelin-blue)
![Chainlink](https://img.shields.io/badge/Price%20Feeds-Chainlink-green)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)