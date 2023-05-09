// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract CoinFlipGameLINK is VRFConsumerBaseV2 {
    // owner of the contract
    address public owner; 
    // minimum bet amount in wei
    uint256 public minimumBet; 
    // percentage of the bet that goes to the contract
    uint256 private constant CONTRACT_FEE_PERCENTAGE = 1; 
    // Address of the LINK token
    address public LINK;
    // The VRF Coordinator
    VRFCoordinatorV2Interface VRFCInterface;
    // Address of the Chainlink VRF Subscription
    uint64 public subId;
    // 30 gwei gas lane on Sepolia
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    // Number of confirmations to wait - min 3 on Sepolia 
    uint16 requestConfirmations = 3;
    // Gas limit for callback fulfillRandomWords
    uint32 callbackGasLimit = 150000;

    // Bet struct
    struct Bet {
        address player;
        uint256 amount;
        bool choice;
        bool won;
        bool paid;
    }

    // mapping of bet IDs to bets
    mapping (uint256 => Bet) private bets; 

    // CoinFlip events
    event BetPlaced(uint256 betId, address player, uint256 amount, bool choice);
    event BetResolved(uint256 betId, address player, uint256 amount, bool choice, bool result, bool won);
    event cashedOut(uint256 betId, address player, uint256 amount);
    event contractReplenished(address user, uint256 amount);

    constructor(address _vrfCoordinator, address _link, uint64 _subID) 
        VRFConsumerBaseV2(_vrfCoordinator) {
            owner = msg.sender;
            minimumBet = 1e16; // set minimum bet to 0.01 ether
            LINK = _link;
            VRFCInterface = VRFCoordinatorV2Interface(_vrfCoordinator);
            subId = _subID;
    }

    // Only the owner can call functions with this modifier 
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the contract owner!");
        _;
    }

    // Flip a coin. Head is true, tails is false
    function placeBet(bool _choice) public payable {
        require(msg.value >= (minimumBet), "Bet amount is too low!"); 

        uint256 betId = requestRandomWords();
        bets[betId] = Bet(msg.sender, msg.value, _choice, false, false);

        emit BetPlaced(betId, msg.sender, msg.value, _choice);
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = VRFCInterface.requestRandomWords(keyHash, subId, requestConfirmations, callbackGasLimit, 1);
        return requestId;
    }

    // Internal function called by the VRF contract. Resolves the bet. 
    function fulfillRandomWords(uint256 _id, uint256[] memory _randomWords) internal override {
        // Determine a win or loss 
        bool result = ((_randomWords[0] %2) == 0);
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
        bets[_id].paid = true;
        payable(bets[_id].player).transfer(payout);
        emit cashedOut(_id, bets[_id].player, bets[_id].amount);
    }

    // Allows owners to withdraw the funds stored in the contract in case of emergency 
    function withdrawCoinflipBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Allows the contract owner to change the minimum bet amount
    function setMinimumBet(uint256 _minimumBet) external onlyOwner {
        minimumBet = _minimumBet;
    }

    // Allows contract owner to update Chainlink VRF parameters 
    function updateVRFParameters(uint64 _subId, bytes32 _keyHash, uint16 _requestConfirmations, uint32 _callbackGasLimit) external onlyOwner {
        subId = _subId;
        keyHash = _keyHash;
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;
    }

    // Allows contract to receive Ether
    receive() external payable {
        emit contractReplenished(msg.sender, msg.value);
    }
}