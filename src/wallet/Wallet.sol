// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PriceConverter} from "../libraries/PriceConverter.sol";

contract Wallet is ReentrancyGuard {
    error Wallet__InsuffiecientFundsToDeposit();
    error Wallet__BalanceIsLessThanAmountToWithdraw();
    error Wallet__AmountTooSmall();
    error GameWallet__TransferFailed();
    error Wallet__InsufficientBalanceToStake();

    mapping(address => uint256) private s_balances;

    uint256 private constant MINIMUM_DEPOSIT = 1;

    AggregatorV3Interface private s_priceFeed;

    using PriceConverter for uint256;

    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event FundsTransferredToGame(address indexed user, uint256 amount);
    event FundsReceivedFromGame(address indexed user, uint256 amount);
    // constructor(address priceFeed){
    //     // s_priceFeed = AggregatorV3Interface(priceFeed);
    // }

    function deposit() external payable nonReentrant {
        if (msg.value /*.getConversionRate(s_priceFeed)*/ < MINIMUM_DEPOSIT) {
            revert Wallet__InsuffiecientFundsToDeposit();
        }

        s_balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant {
        uint256 balance = s_balances[msg.sender];

        if (amount > balance) {
            revert Wallet__BalanceIsLessThanAmountToWithdraw();
        }
        if (amount == 0) {
            revert Wallet__AmountTooSmall();
        }

        balance -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert GameWallet__TransferFailed();
        }
        emit FundsWithdrawn(msg.sender, amount);
    }

    function deductFunds(address user, uint256 amount) external nonReentrant returns (bool) {
        if (amount > s_balances[user]) {
            revert Wallet__InsufficientBalanceToStake();
        }
        s_balances[user] -= amount;
        emit FundsTransferredToGame(user, amount);
        return true;
    }

    function addWinnings(address user, uint256 amount) external nonReentrant {
        s_balances[user] += amount;
        emit FundsReceivedFromGame(user, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return s_balances[user];
    }

    function getMinimumDeposit() external pure returns (uint256) {
        return MINIMUM_DEPOSIT;
    }
}
