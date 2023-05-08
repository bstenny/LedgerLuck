// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Interface for Randomizer.ai VRF
interface vrf {
    function request(uint256 callbackGasLimit) external returns (uint256);
    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
    function clientWithdrawTo(address _to, uint256 _amount) external;
    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);
    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);
}

contract CoinFlipGame {
    // owner of the contract
    address public owner; 
    // minimum bet amount in wei
    uint256 public minimumBet; 
    // percentage of the bet that goes to the contract
    uint256 private constant CONTRACT_FEE_PERCENTAGE = 1; 
    // Randomizer.ai on Arbitrum Goerli 
    vrf public randomizer = vrf(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc);

    struct Bet {
        address player;
        uint256 amount;
        bool choice;
        bool won;
        bool paid;
    }

    mapping (uint256 => Bet) private bets; // mapping of bet IDs to bets

    event BetPlaced(uint256 betId, address player, uint256 amount, bool choice);
    event BetResolved(uint256 betId, address player, uint256 amount, bool choice, bool result, bool won);
    event cashedOut(uint256 betId, address player, uint256 amount);

    constructor() {
        owner = msg.sender;
        minimumBet = 0.1 ether; // set minimum bet to 0.1 ether
    }
    // Fallback function to receive ETH without a function call. It's supposed to be empty
    fallback() external payable {
    }

    // Flip a coin. Head is true, tails is false
    function placeBet(bool choice) public payable {
        // Estimate the VRF fee and revert if user cannot cover the fee 
        uint256 vrffee = randomizer.estimateFee(50000, 4);
        require(msg.value >= (minimumBet + vrffee), "Bet amount or VRF Fee is too low!"); 

        uint256 betId = randomizer.request(50000, 4);
        bets[betId] = Bet(msg.sender, (msg.value - vrffee), choice, false, false);

        emit BetPlaced(betId, msg.sender, (msg.value - vrffee), choice);
    }

    // Function called by the VRF contract. Resolves the bet. 
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        // Require caller to be VRF contract 
        require(msg.sender == address(randomizer), "Caller is not VRF contract!");
        // Determine a win or loss 
        bool result = ((uint256(_value) %2) == 0);
        bool won = (result == bets[_id].choice);
        // Log results and emit event
        bets[_id].won = won;
        emit BetResolved(_id, bets[_id].player, bets[_id].amount, bets[_id].choice, result, won);
        
    }

    // Cash out a winning bet
    function cashout(uint256 _id) public {
        // Only the player who placed the bet can cashout 
        require(msg.sender == bets[_id].player, "Only the person who placed the bet can cash out!");
        // Require a win to cashout
        require(bets[_id].won == true);
        // Check if user has already cashed this bet out
        require(bets[_id].paid == false);
        // Check if the contract has enough funds to pay out 
        uint256 payout = bets[_id].amount * 2 * (100 - CONTRACT_FEE_PERCENTAGE) / 100;
        require(address(this).balance >= payout, "Insufficient funds in contract to cash out.");
        // Pay out and update bet struct
        payable(bets[_id].player).transfer(payout);
        bets[_id].paid = true;
        emit cashedOut(_id, bets[_id].player, bets[_id].amount);
        
    }

    // Allows owners to withdraw the funds stored in the contract in case of emergency 
    function withdrawContractBalance() public {
        require(msg.sender == owner, "Only the contract owner can withdraw the contract balance");
        payable(owner).transfer(address(this).balance);
    }
}
