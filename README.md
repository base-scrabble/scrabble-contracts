# 🎮 Decentralized Scrabble Smart Contracts

This project implements the core logic for a decentralized Scrabble game on the blockchain, utilizing Solidity smart contracts. Players can create and join games, stake funds, and settle game results securely and transparently.

## ✨ Features

*   **Decentralized Game Logic**: Core Scrabble game state and rules managed entirely on-chain.
*   **Secure Fund Management**: Players interact with an integrated `Wallet` contract to deposit, withdraw, and manage their game stakes with reentrancy protection.
*   **Reentrancy Protection**: Critical contract functions are safeguarded against reentrancy attacks using OpenZeppelin's `ReentrancyGuard`.
*   **EIP712 Signature Verification**: Game results are submitted off-chain and verified on-chain using EIP712 typed structured data hashing and ECDSA signatures from both players, ensuring data integrity and player consensus.
*   **Chainlink Price Feed Integration**: Includes a `PriceConverter` library for potential integration with Chainlink `AggregatorV3Interface` to obtain real-time asset prices, enabling dynamic stake calculations (currently commented out in main contracts but available).
*   **Fork-Based Deployment Script**: A `Foundry` script (`DeployScrabble.s.sol`) facilitates easy and repeatable deployment of the Scrabble and Wallet contracts.

## 🚀 Getting Started

To get a copy of this project up and running on your local machine, follow these steps.

### Prerequisites

Ensure you have [Foundry](https://book.getfoundry.sh/getting-started/installation) installed. Foundry is a blazing fast, portable, and modular toolkit for Ethereum application development written in Rust.

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installation

1.  **Clone the Repository**:

    ```bash
    git clone https://github.com/base-scrabble/scrabble-contracts.git
    cd scrabble-contracts
    ```

2.  **Install Dependencies**:
    Initialize and update the git submodules for OpenZeppelin and Chainlink contracts.

    ```bash
    forge install
    ```

3.  **Build the Project**:
    Compile the smart contracts.

    ```bash
    forge build
    ```

4.  **Run Tests (Optional but Recommended)**:
    Execute the test suite to ensure everything is functioning as expected.

    ```bash
    forge test
    ```

## 🎮 Usage

The core interaction with the Scrabble game involves the `Wallet` and `Scrabble` smart contracts. Players will typically interact with these contracts through a dApp front-end or directly via tools like `cast` or web3 libraries.

### Wallet Contract Interaction

Players first need to deposit funds into their associated wallet within the system before participating in games.

*   **Deposit Funds**: Send ETH directly to the `deposit()` function.
    ```solidity
    function deposit() external payable nonReentrant;
    ```
*   **Withdraw Funds**: Withdraw available funds from the wallet.
    ```solidity
    function withdraw(uint256 amount) external nonReentrant;
    ```
*   **Check Balance**: Query the balance for any address.
    ```solidity
    function getBalance(address user) external view returns (uint256);
    ```

### Scrabble Game Workflow

1.  **Create a Game**:
    A player initiates a new game by calling `createGame` with their desired stake. The funds are deducted from their wallet and locked.

    ```solidity
    function createGame(uint256 stakeAmount) external nonReentrant returns (uint256 gameId);
    ```

    *Example Interaction (Hypothetical Client-side)*:
    ```javascript
    // Assume `scrabbleContract` is an instance of the Scrabble contract
    const stakeAmount = web3.utils.toWei("0.1", "ether"); // 0.1 ETH
    const tx = await scrabbleContract.methods.createGame(stakeAmount).send({ from: player1Address });
    const gameId = tx.events.GameCreated.returnValues.gameId;
    console.log(`Game created with ID: ${gameId}`);
    ```

2.  **Join a Game**:
    A second player joins an existing game by calling `joinGame` with the matching `gameId` and `stakeAmount`. Their funds are also locked.

    ```solidity
    function joinGame(uint256 gameId, uint256 stakeAmount) external nonReentrant;
    ```

    *Example Interaction (Hypothetical Client-side)*:
    ```javascript
    // Assume `scrabbleContract` is an instance of the Scrabble contract
    const gameIdToJoin = 1; // Example game ID
    const stakeAmount = web3.utils.toWei("0.1", "ether"); // Must match player1's stake
    await scrabbleContract.methods.joinGame(gameIdToJoin, stakeAmount).send({ from: player2Address });
    console.log(`Player 2 joined game ${gameIdToJoin}`);
    ```

3.  **Submit Result**:
    After the game is played (off-chain), the result (winner, scores, final board hash) is signed by both players. One of the players then submits these signatures along with the game data to the `submitResult` function for on-chain verification and payout.

    ```solidity
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
    ) external nonReentrant;
    ```

    *Example Signature Generation (Conceptual)*:
    Both players would sign a message digest derived from the game results using `_hashTypedDataV4`.
    ```javascript
    // Conceptual flow for client-side signature
    const message = {
        gameId: gameId,
        player1: player1Address,
        player2: player2Address,
        winner: winnerAddress,
        finalBoardHash: "0x...",
        p1Score: 150,
        p2Score: 120,
        nonce: Math.floor(Math.random() * 1e18),
        timestamp: Math.floor(Date.now() / 1000),
        roundNumber: 1
    };
    // Player 1 signs `message` -> sigP1
    // Player 2 signs `message` -> sigP2

    // One player then calls submitResult with message and both signatures
    await scrabbleContract.methods.submitResult(
        message.gameId,
        message.winner,
        message.finalBoardHash,
        message.p1Score,
        message.p2Score,
        message.nonce,
        sigP1,
        sigP2,
        message.timestamp,
        message.roundNumber
    ).send({ from: player1Address }); // or player2Address
    ```

### Deployment

To deploy the contracts to a live network or a local testnet, use the provided Forge script.

```bash
forge script script/DeployScrabble.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast --verify --etherscan-api-key <YOUR_ETHERSCAN_API_KEY> -vvvv
```

Replace `<YOUR_RPC_URL>`, `<YOUR_PRIVATE_KEY>`, and `<YOUR_ETHERSCAN_API_KEY>` with your actual network details.

## 🛠️ Technologies Used

| Technology                                                 | Description                                                                                             |
| :--------------------------------------------------------- | :------------------------------------------------------------------------------------------------------ |
| [Solidity](https://soliditylang.org/)                      | Primary language for writing smart contracts.                                                           |
| [Foundry](https://book.getfoundry.sh/)                     | Ethereum development toolkit used for compiling, testing, and deploying contracts.                        |
| [OpenZeppelin Contracts](https://docs.openzeppelin.com/)   | Industry-standard library for secure smart contract development, providing `ReentrancyGuard` and `EIP712`. |
| [Chainlink](https://chainlinklabs.com/)                    | Decentralized oracle network providing external data, specifically `AggregatorV3Interface` for price feeds. |

## 🤝 Contributing

Contributions are welcome! If you have suggestions for improvements, feature requests, or bug reports, please feel free to:

*   🌐 Fork the repository.
*   💡 Create a new branch for your feature or bugfix.
*   👨‍💻 Make your changes and ensure tests pass.
*   ⬆️ Submit a pull request.

Please ensure your code adheres to the existing style and quality standards.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author
 Adebakin Olujimi
 Edetan Bonaventure
 Peter Arogundade

*   LinkedIn: [https://linkedin.com/in/your_username](https://linkedin.com/in/your_username)
*   Twitter: [https://twitter.com/your_username](https://twitter.com/your_username)
*   Portfolio: [https://your-portfolio.com](https://your-portfolio.com)

---

[![Foundry](https://img.shields.io/badge/Made%20with-Foundry-critical?style=flat&logo=foundry)](https://book.getfoundry.sh/)
[![Solidity](https://img.shields.io/badge/Language-Solidity-black?style=flat&logo=solidity)](https://soliditylang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/base-scrabble/scrabble-contracts/actions)

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)