// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// PLACEHOLDER FOR ACTUAL RANDOM NUMBER GENERATOR CONTRACT
interface IRandomNumberGenerator {
    function getRandomNumber(uint256 max) external returns (uint256);
}

contract DiceRollGame {
    address public owner; // owner of the contract
    uint256 public minimumBet; // minimum bet amount in wei
    uint256 public contractBalance; // balance of the contract
    uint256 private constant CONTRACT_FEE_PERCENTAGE = 1; // percentage of the bet that goes to the contract
    uint256 private constant MAX_NUMBER = 6; // maximum number on the dice

    struct Bet {
        address player;
        uint256 amount;
        uint256 guess;
    }

    mapping (bytes32 => Bet) private bets; // mapping of bet IDs to bets

    IRandomNumberGenerator private rng; // instance of the random number generator contract

    event BetPlaced(bytes32 betId, address player, uint256 amount, uint256 guess);
    event BetResolved(bytes32 betId, address player, uint256 amount, uint256 guess, uint256 result, bool won);

    constructor(address randomNumberGenerator) {
        owner = msg.sender;
        minimumBet = 0.1 ether; // set minimum bet to 0.1 ether
        rng = IRandomNumberGenerator(randomNumberGenerator);
    }

    function placeBet(uint256 guess) public payable {
        require(msg.value >= minimumBet, "Bet amount is too low");
        require(guess >= 1 && guess <= MAX_NUMBER, "Invalid guess");

        bytes32 betId = keccak256(abi.encodePacked(msg.sender, block.timestamp)); // generate a unique ID for the bet
        bets[betId] = Bet(msg.sender, msg.value, guess);

        emit BetPlaced(betId, msg.sender, msg.value, guess);
    }

    function resolveBet(bytes32 betId) public {
        Bet storage bet = bets[betId];
        require(bet.player == msg.sender, "Only the player who placed the bet can resolve it");

        uint256 result = rng.getRandomNumber(MAX_NUMBER); // generate a random number between 1 and 6
        bool won = result == bet.guess;
        uint256 payout = 0;

        if (won) {
            payout = bet.amount * (2 - CONTRACT_FEE_PERCENTAGE) / 1; // calculate the payout
            contractBalance += bet.amount - payout; // add the contract fee to the contract balance
            payable(bet.player).transfer(payout); // transfer the winnings to the player
        } else {
            contractBalance += bet.amount; // add the bet amount to the contract balance
        }

        delete bets[betId]; // delete the bet

        emit BetResolved(betId, bet.player, bet.amount, bet.guess, result, won);
    }

    function withdrawContractBalance() public {
        require(msg.sender == owner, "Only the contract owner can withdraw the contract balance");
        uint256 balance = contractBalance;
        contractBalance = 0;
        payable(owner).transfer(balance);
    }
}
