// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CoinFlipGame {
    address public owner; // owner of the contract
    uint256 public minimumBet; // minimum bet amount in wei
    uint256 public contractBalance; // balance of the contract
    uint256 private constant CONTRACT_FEE_PERCENTAGE = 1; // percentage of the bet that goes to the contract

    struct Bet {
        address player;
        uint256 amount;
        bool choice;
    }

    mapping (bytes32 => Bet) private bets; // mapping of bet IDs to bets

    event BetPlaced(bytes32 betId, address player, uint256 amount, bool choice);
    event BetResolved(bytes32 betId, address player, uint256 amount, bool choice, bool result, bool won);

    constructor() {
        owner = msg.sender;
        minimumBet = 0.1 ether; // set minimum bet to 0.1 ether
    }

    function placeBet(bool choice) public payable {
        require(msg.value >= minimumBet, "Bet amount is too low");

        bytes32 betId = keccak256(abi.encodePacked(msg.sender, block.timestamp)); // generate a unique ID for the bet
        bets[betId] = Bet(msg.sender, msg.value, choice);

        emit BetPlaced(betId, msg.sender, msg.value, choice);
    }

    function resolveBet(bytes32 betId, bool result) public {
        Bet storage bet = bets[betId];
        require(bet.player == msg.sender, "Only the player who placed the bet can resolve it");

        bool won = result == bet.choice;
        uint256 payout = 0;

        if (won) {
            payout = bet.amount * (2 - CONTRACT_FEE_PERCENTAGE) / 1; // calculate the payout
            contractBalance += bet.amount - payout; // add the contract fee to the contract balance
            payable(bet.player).transfer(payout); // transfer the winnings to the player
        } else {
            contractBalance += bet.amount; // add the bet amount to the contract balance
        }

        delete bets[betId]; // delete the bet

        emit BetResolved(betId, bet.player, bet.amount, bet.choice, result, won);
    }

    function withdrawContractBalance() public {
        require(msg.sender == owner, "Only the contract owner can withdraw the contract balance");
        uint256 balance = contractBalance;
        contractBalance = 0;
        payable(owner).transfer(balance);
    }

    function flipCoin() private view returns (bool) {
        return block.timestamp % 2 == 0; // use the current timestamp as a source of randomness to flip the coin
    }
}
