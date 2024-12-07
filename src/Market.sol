// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";

/// @title Market - Betting market contract
/// @notice Handles betting operations and winnings distribution
contract Market {
    // === State Variables ===
    struct Bet {
        address bettor;
        uint256 amount;
        uint8 outcomeIndex;
        uint256 timestamp;
    }
    
    address public creator;
    string public description;
    string[] public outcomes;
    uint256 public bettingDeadline;
    bool public resolved;
    uint8 public winningOutcome;
    
    uint256 public constant MIN_BET_AMOUNT = 0.01 BNB;
    uint256 public constant MAX_BET_AMOUNT = 100 BNB;
    
    mapping(uint8 => uint256) public outcomePools;
    mapping(address => Bet) public bets;
    mapping(address => bool) public claimed;
    
    IOracle public oracle;
    uint256 public constant PLATFORM_FEE = 10; // 1% in basis points
    address public feeCollector;
    bytes32 public marketId;
    
    // === Events ===
    event BetPlaced(address indexed bettor, uint256 amount, uint8 outcomeIndex);
    event MarketResolved(uint8 winningOutcome);
    event WinningsClaimed(address indexed claimant, uint256 payout);
    
    // === Constructor ===
    constructor(
        address _creator,
        string memory _description,
        string[] memory _outcomes,
        uint256 _bettingDeadline,
        address _oracle,
        address _feeCollector
    ) {
        creator = _creator;
        description = _description;
        outcomes = _outcomes;
        bettingDeadline = _bettingDeadline;
        oracle = IOracle(_oracle);
        feeCollector = _feeCollector;
        marketId = keccak256(abi.encodePacked(
            block.timestamp,
            _creator,
            _description
        ));
    }
    
    // === External Functions ===
    function placeBet(uint8 outcomeIndex) external payable {
        // Checks
        require(outcomeIndex < outcomes.length, "Invalid outcome index");
        require(block.timestamp < bettingDeadline, "Betting is closed");
        require(msg.value >= MIN_BET_AMOUNT, "Bet amount too low (min 0.01 BNB)");
        require(msg.value <= MAX_BET_AMOUNT, "Bet amount too high (max 100 BNB)");
        
        // Calculate fee in BNB
        uint256 fee = (msg.value * PLATFORM_FEE) / 1000;
        uint256 betAmount = msg.value - fee;
        
        // Update state
        outcomePools[outcomeIndex] += betAmount;
        bets[msg.sender] = Bet(msg.sender, betAmount, outcomeIndex, block.timestamp);
        
        // Transfer fee
        (bool success, ) = payable(feeCollector).call{value: fee}("");
        require(success, "Fee transfer failed");
        
        emit BetPlaced(msg.sender, betAmount, outcomeIndex);
    }
    
    function resolveMarket() external {
        require(msg.sender == creator, "Only creator can resolve");
        require(!resolved, "Already resolved");
        require(block.timestamp >= bettingDeadline, "Too early to resolve");

        // Get result from oracle
        (uint8 result, bool isValid) = oracle.getResult(marketId);
        require(isValid, "Invalid oracle result");
        require(result < outcomes.length, "Invalid outcome");

        resolved = true;
        winningOutcome = result;
        emit MarketResolved(result);
    }
    
    function claimWinnings() external {
        // Checks
        require(resolved, "Market not resolved yet");
        require(!claimed[msg.sender], "Already claimed");
        Bet storage userBet = bets[msg.sender];
        require(userBet.outcomeIndex == winningOutcome, "Not a winning bet");
        uint256 payout = (userBet.amount * address(this).balance) / outcomePools[winningOutcome];
        
        // Effects
        claimed[msg.sender] = true;
        
        // Interactions
        (bool success, ) = payable(msg.sender).call{value: payout}("");
        require(success, "Transfer failed");
        emit WinningsClaimed(msg.sender, payout);
    }
    
    // === Fallback Functions ===
    receive() external payable {}
    fallback() external payable {}
}