🎲 **BaseScrabble Smart Contracts**

## Overview
BaseScrabble is a decentralized gaming platform built on Solidity, designed to facilitate secure and verifiable Scrabble-like games on the blockchain. It integrates robust access control, a multi-token wallet for managing player stakes, and Chainlink price feeds for accurate value conversions, ensuring a transparent and fair gaming environment.

## Features
*   ✨ **Decentralized Game Logic**: Core game mechanics for creating, joining, and settling games are fully on-chain.
*   💰 **Multi-Token Staking**: Supports staking in native ETH, USDT, and USDC, allowing players flexibility in their preferred currency.
*   🔐 **Role-Based Access Control**: Leverages OpenZeppelin's `AccessControl` for granular permission management within the ecosystem.
*   🛡️ **Secure Backend Authentication**: Implements EIP-712 structured data hashing for secure and auditable player and backend interactions.
*   📊 **Real-time Price Feeds**: Integrates Chainlink `AggregatorV3Interface` to fetch reliable ETH/USD prices for dynamic stake conversions.
*   🔄 **Reentrancy Guard**: Critical functions are protected against reentrancy attacks, enhancing contract security.
*   ⏸️ **Pausable System**: Includes an emergency pause mechanism for administrators to mitigate unforeseen risks.
*   🚫 **Blacklisting & KYC Management**: Provides on-chain tools for managing blacklisted addresses and KYC verification status.

## Getting Started

To set up and interact with the BaseScrabble smart contracts locally, follow these steps. This project uses [Foundry](https://getfoundry.sh/), a blazing-fast, portable, and modular toolkit for Ethereum application development.

### Installation

*   🛠️ **Install Foundry**:
    If you don't have Foundry installed, run the following command:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

*   📦 **Clone the Repository**:
    ```bash
    git clone https://github.com/base-scrabble/scrabble-contracts.git
    cd scrabble-contracts
    ```

*   📥 **Install Dependencies (Git Submodules)**:
    This project relies on OpenZeppelin and Chainlink contracts as submodules.
    ```bash
    git submodule update --init --recursive
    ```

*   ⚙️ **Compile Contracts**:
    Compile the Solidity smart contracts using Forge:
    ```bash
    forge build
    ```

*   🧪 **Run Tests**:
    Execute the unit and integration tests to ensure everything is working correctly:
    ```bash
    forge test
    ```




     
  📝 Project Contracts & Configuration
This section provides a quick overview of the essential contract addresses and configuration details for the project.

⚙️ Contract Addresses
Access Manager: 0x0900b2fb8671a8b9846a3F7B030b39F8D8c94f2e

Base Scrabble: 0xC15b61947746e0C31484567185111fe87eda6350

Wallet Contract: 0x9c5d8960e9058F512215650b21B15264A5C324cf

🔗 Other Details
Base Sepolia Price Feed: 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70

Wallet USDC Address: 0x323e78f944A9a1FcF3a10efcC5319DBb0bB6e673

Wallet USDT Address: 0x036CbD53842c5426634e7929541eC2318f3dCF7e

Base Sepolia Submitter: 0x0

Base Sepolia Backend Signer: 0x0

Deployer Private Key: 0x0

Base Sepolia Super Admin: 0x0

Base Sepolia Etherscan API Key: =

ETHERSCAN_API_KEY: =




### Environment Variables

The project requires several environment variables for deployment and interaction, especially for different networks. Create a `.env` file in the root directory and populate it with the required values.

| Variable Name                | Description                                        | Example Value (Base Sepolia)                 |
| :--------------------------- | :------------------------------------------------- | :------------------------------------------- |
| `ETHEREUM_SEPOLIA_SUPER_ADMIN` | Super admin address for Ethereum Sepolia network.  | `0xYourEthereumSepoliaAdminAddress`          |
| `BASE_SEPOLIA_SUPER_ADMIN`   | Super admin address for Base Sepolia network.      | `0xYourBaseSepoliaAdminAddress`              |
| `BASE_MAINNET_SUPER_ADMIN`   | Super admin address for Base Mainnet.              | `0xYourBaseMainnetAdminAddress`              |
| `DEFAULT_SUPER_ADMIN`        | Default super admin address for local development. | `0xYourLocalAdminAddress`                    |
| `ETHEREUM_SEPOLIA_WALLET`    | Wallet contract address for Ethereum Sepolia.      | `0xYourEthereumSepoliaWalletAddress`         |
| `ETHEREUM_SEPOLIA_SUBMITTER` | Submitter address for Ethereum Sepolia.            | `0xYourEthereumSepoliaSubmitterAddress`      |
| `ETHEREUM_SEPOLIA_BACKEND_SIGNER` | Backend signer address for Ethereum Sepolia.    | `0xYourEthereumSepoliaBackendSignerAddress`  |
| `ETHEREUM_SEPOLIA_USDT`      | USDT token address for Ethereum Sepolia.           | `0xYourEthereumSepoliaUSDTAddress`           |
| `ETHEREUM_SEPOLIA_USDC`      | USDC token address for Ethereum Sepolia.           | `0xYourEthereumSepoliaUSDCAddress`           |
| `ETHEREUM_SEPOLIA_PRICE_FEED` | ETH/USD price feed address for Ethereum Sepolia. | `0xYourEthereumSepoliaPriceFeedAddress`      |
| `BASE_SEPOLIA_WALLET_ADDRESS` | Wallet contract address for Base Sepolia.         | `0xYourBaseSepoliaWalletAddress`             |
| `BASE_SEPOLIA_SUBMITTER`     | Submitter address for Base Sepolia.                | `0xYourBaseSepoliaSubmitterAddress`          |
| `BASE_SEPOLIA_BACKEND_SIGNER` | Backend signer address for Base Sepolia.          | `0xYourBaseSepoliaBackendSignerAddress`      |
| `BASE_SEPOLIA_USDT`          | USDT token address for Base Sepolia.               | `0xYourBaseSepoliaUSDTAddress`               |
| `BASE_SEPOLIA_USDC`          | USDC token address for Base Sepolia.               | `0xYourBaseSepoliaUSDCAddress`               |
| `BASE_SEPOLIA_PRICE_FEED`    | ETH/USD price feed address for Base Sepolia.       | `0xYourBaseSepoliaPriceFeedAddress`          |
| `BASE_MAINNET_WALLET`        | Wallet contract address for Base Mainnet.          | `0xYourBaseMainnetWalletAddress`             |
| `BASE_MAINNET_SUBMITTER`     | Submitter address for Base Mainnet.                | `0xYourBaseMainnetSubmitterAddress`          |
| `BASE_MAINNET_BACKEND_SIGNER` | Backend signer address for Base Mainnet.          | `0xYourBaseMainnetBackendSignerAddress`      |
| `BASE_MAINNET_USDT`          | USDT token address for Base Mainnet.               | `0xYourBaseMainnetUSDTAddress`               |
| `BASE_MAINNET_USDC`          | USDC token address for Base Mainnet.               | `0xYourBaseMainnetUSDCAddress`               |
| `BASE_MAINNET_PRICE_FEED`    | ETH/USD price feed address for Base Mainnet.       | `0xYourBaseMainnetPriceFeedAddress`          |
| `DEFAULT_WALLET`             | Default wallet address for local development.      | `0xYourLocalWalletAddress`                   |
| `DEFAULT_SUBMITTER`          | Default submitter address for local development.   | `0xYourLocalSubmitterAddress`                |
| `DEFAULT_BACKEND_SIGNER`     | Default backend signer for local development.      | `0xYourLocalBackendSignerAddress`            |
| `DEFAULT_USDT`               | Default USDT address for local development.        | `0xYourLocalUSDTAddress`                     |
| `DEFAULT_USDC`               | Default USDC address for local development.        | `0xYourLocalUSDCAddress`                     |
| `DEFAULT_PRICE_FEED`         | Default price feed address for local development.  | `0xYourLocalPriceFeedAddress`                |
| `ETHEREUM_SEPOLIA_RPC_URL`   | RPC URL for Ethereum Sepolia.                      | `https://eth-sepolia.g.alchemy.com/v2/KEY`   |
| `BASE_SEPOLIA_RPC_URL`       | RPC URL for Base Sepolia.                          | `https://base-sepolia.g.alchemy.com/v2/KEY`  |
| `BASE_MAINNET_RPC_URL`       | RPC URL for Base Mainnet.                          | `https://base-mainnet.g.alchemy.com/v2/KEY`  |
| `ANVIL_RPC_URL`              | RPC URL for local Anvil network.                   | `http://127.0.0.1:8545`                      |
| `ETHEREUM_SEPOLIA_ETHERSCAN_API_KEY` | Etherscan API key for Ethereum Sepolia.    | `YOUR_ETHERSCAN_API_KEY`                     |
| `BASE_SEPOLIA_ETHERSCAN_API_KEY` | Etherscan API key for Base Sepolia.          | `YOUR_BASESCAN_API_KEY`                      |
| `BASE_MAINNET_ETHERSCAN_API_KEY` | Etherscan API key for Base Mainnet.          | `YOUR_BASESCAN_API_KEY`                      |

## Usage

Interacting with the BaseScrabble contracts primarily involves deployment, managing access, funding the wallet, and then orchestrating game creation, joining, and settlement.

### Deployment

To deploy the contracts to a local Anvil instance or a testnet:

1.  **Start Anvil (for local development)**:
    ```bash
    anvil
    ```
2.  **Deploy AccessManager**:
    ```bash
    forge script script/deployAccessManager/DeployAccessManager.s.sol:DeployAccessManager --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
    ```
3.  **Deploy Mock ERC20 Tokens (if on local/testnet)**:
    ```bash
    forge script script/deployMocks/DeployMocks.s.sol:DeployMocks --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
    ```
4.  **Deploy Wallet Contract**:
    ```bash
    forge script script/deployWallet/DeployWallet.s.sol:DeployWallet --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
    ```
5.  **Deploy Scrabble Game Contract**:
    ```bash
    forge script script/deployScrabble/DeployScrabble.s.sol:DeployScrabble --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
    ```
    *Note: Replace `$BASE_SEPOLIA_RPC_URL` and `$PRIVATE_KEY` with your actual environment variables.*

### Interacting with Contracts

Once deployed, interactions typically follow this flow:

1.  **Access Management**:
    The `AccessManager` contract controls roles, KYC status, and blacklists.
    *   **Granting Roles**: The `superAdmin` can grant roles like `ADMIN_ROLE`, `AUDITOR_ROLE`, `REALTOR_ROLE`, `INVESTOR_ROLE`, `TENANT_ROLE`, and `TOKEN_ADMIN_ROLE`.
        ```solidity
        accessManager.grantRole(ACCESS_MANAGER.AUDITOR_ROLE(), someAuditorAddress);
        ```
    *   **Setting KYC Status**:
        ```solidity
        accessManager.setKYC(playerAddress, true);
        ```
    *   **Blacklisting Users**:
        ```solidity
        accessManager.blacklist(maliciousAddress, true);
        ```
    *   **Pausing/Unpausing**:
        ```solidity
        accessManager.pause();
        accessManager.unpause();
        ```

2.  **Wallet Operations**:
    The `Wallet` contract manages user funds for staking.

    *   **Authorizing Game Contracts**: An administrator must authorize game contracts to interact with the wallet.
        ```solidity
        wallet.setAuthorizedCaller(address(scrabbleContract), true);
        ```
    *   **Depositing ETH (requires backend signature)**:
        Users send ETH to the wallet via the `depositETH` function. This transaction needs to be authorized by the `i_backendSigner` using an EIP-712 signature. The backend would provide `backendSig`.
        ```solidity
        // Example call (simplified, actual interaction would involve backend logic for backendSig)
        wallet.depositETH{value: 1 ether}(backendSig);
        ```
    *   **Depositing ERC20 (USDT/USDC - requires prior approval and backend signature)**:
        Users must first `approve` the `Wallet` contract to spend their tokens, then call `depositToken`.
        ```solidity
        // First, approve the Wallet contract to spend tokens
        IERC20(usdtAddress).approve(address(wallet), amountToDeposit);

        // Then, call depositToken (backend provides signature)
        wallet.depositToken(usdtAddress, amountToDeposit, backendSig);
        ```
    *   **Withdrawing ETH (requires backend signature)**:
        ```solidity
        wallet.withdrawETH(amountInWei, backendSig);
        ```
    *   **Withdrawing ERC20 (requires backend signature)**:
        ```solidity
        wallet.withdrawToken(usdtAddress, amountToWithdraw, backendSig);
        ```

3.  **Scrabble Game Lifecycle**:
    The `Scrabble` contract manages game creation, joining, and settlement.

    *   **Create Game (requires backend signature)**:
        A player initiates a new game, defining the stake amount and token.
        ```solidity
        scrabble.createGame(stakeAmount, tokenAddress, backendSig);
        ```
    *   **Join Game (requires backend signature)**:
        Another player joins an existing game, matching the initial stake.
        ```solidity
        scrabble.joinGame(gameId, stakeAmount, backendSig);
        ```
    *   **Cancel Game (creator only, if lobby expired and no other players, requires backend signature)**:
        The game creator can cancel an un-joined game if the lobby timeout has passed.
        ```solidity
        scrabble.cancelGame(gameId, backendSig);
        ```
    *   **Submit Result (submitter only)**:
        The designated `i_submitter` (a centralized entity in this implementation, likely an off-chain game server) submits the game results.
        ```solidity
        scrabble.submitResult(gameId, winnerAddress, finalBoardHash, playerScores, roundNumber);
        ```
        *   `gameId`: The unique ID of the game.
        *   `winnerAddress`: Address of the winning player (or `address(0)` for a draw).
        *   `finalBoardHash`: A content-addressed hash of the final game board for off-chain verification.
        *   `playerScores`: An array of `uint32` scores, corresponding to the `players` array in the `Game` struct.
        *   `roundNumber`: The current round number to prevent stale submissions.

## Technologies Used

| Technology | Category           | Description                                                               | Link                                                    |
| :--------- | :----------------- | :------------------------------------------------------------------------ | :------------------------------------------------------ |
| Solidity   | Smart Contract Language | Object-oriented language for implementing smart contracts on EVM.       | [Solidity Lang](https://soliditylang.org/)              |
| Foundry    | Development Framework   | Fast, portable, and modular toolkit for Ethereum development.           | [Foundry Docs](https://book.getfoundry.sh/)             |
| OpenZeppelin | Standard Libraries | Secure and community-audited smart contract components (AccessControl, ERC20, Pausable, ReentrancyGuard, EIP712). | [OpenZeppelin Contracts](https://openzeppelin.com/contracts/) |
| Chainlink  | Oracle Networks    | Decentralized oracle network providing real-world data to smart contracts (Price Feeds). | [Chainlink Docs](https://chain.link/docs)               |
| EIP-712    | Cryptographic Standard | Standard for hashing and signing of structured data.                      | [EIP-712](https://eips.ethereum.org/EIPS/eip-712)       |

## Contributing

We welcome contributions to the BaseScrabble project! If you're looking to enhance features, fix bugs, or improve documentation, please follow these guidelines:

*   🍴 **Fork the repository**.
*   📥 **Clone your forked repository locally**.
*   🌿 **Create a new branch** for your feature or bug fix: `git checkout -b feature/your-feature-name`.
*   🚀 **Make your changes**.
*   ✅ **Write tests** for your changes.
*   🚦 **Ensure all tests pass**: `forge test`.
*   🧹 **Lint your code** and ensure it follows the project's style.
*   💬 **Commit your changes** with a descriptive message: `git commit -m "feat: Add new game mode"`.
*   ⬆️ **Push your branch** to your forked repository.
*   🗣️ **Open a pull request** to the `main` branch of the original repository, describing your changes in detail.

## License

This project is licensed under the MIT License. See the [LICENSE](https://opensource.org/licenses/MIT) file for details.

## Author Info

**Adebakin Olujimi**
*   LinkedIn: [Adebakin Olujimi's LinkedIn](https://www.linkedin.com/in/your-linkedin-username/)
*   Twitter: [@your_twitter_handle](https://twitter.com/your_twitter_handle)
*   Portfolio: [Your Portfolio Link](https://your.portfolio.com)

---

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Powered%20by-Foundry-red)](https://getfoundry.sh/)
[![OpenZeppelin](https://img.shields.io/badge/Built%20with-OpenZeppelin-lightgrey)](https://openzeppelin.com/contracts/)
[![Chainlink](https://img.shields.io/badge/Oracles-Chainlink-orange)](https://chain.link/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
