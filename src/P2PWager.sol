// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WagerOracle.sol";

/// @title P2PWager - Peer-to-peer betting contract
/// @notice Manages direct wagers between two parties
contract P2PWager {
    // === State Variables ===
    WagerOracle public oracle;
    
    struct Wager {
        address creator;
        address counterparty;
        uint256 amount;
        string topic;
        string condition;
        uint256 deadline;
        bool resolved;
        bool creatorWins;
    }
    
    mapping(bytes32 => Wager) public wagers;
    
    // === Events ===
    event WagerCreated(
        bytes32 indexed wagerId,
        address indexed creator,
        string topic,
        string condition,
        uint256 amount
    );
    event WagerAccepted(bytes32 indexed wagerId, address indexed counterparty);
    event WagerResolved(bytes32 indexed wagerId, address winner);
    
    // === Constructor ===
    constructor(address _oracle) {
        oracle = WagerOracle(_oracle);
    }
    
    // === External Functions ===
    function createWager(
        string calldata topic,
        string calldata condition,
        uint256 deadline
    ) external payable returns (bytes32) {
        // Checks
        require(msg.value > 0, "Must wager some ETH");
        require(deadline > block.timestamp, "Invalid deadline");
        
        // Effects
        bytes32 wagerId = keccak256(
            abi.encodePacked(
                msg.sender,
                topic,
                condition,
                block.timestamp
            )
        );
        
        wagers[wagerId] = Wager({
            creator: msg.sender,
            counterparty: address(0),
            amount: msg.value,
            topic: topic,
            condition: condition,
            deadline: deadline,
            resolved: false,
            creatorWins: false
        });
        
        // Interactions (events)
        emit WagerCreated(wagerId, msg.sender, topic, condition, msg.value);
        return wagerId;
    }
    
    function acceptWager(bytes32 wagerId) external payable {
        // Checks
        Wager storage wager = wagers[wagerId];
        require(wager.creator != address(0), "Wager doesn't exist");
        require(wager.counterparty == address(0), "Already accepted");
        require(msg.value == wager.amount, "Must match wager amount");
        
        // Effects
        wager.counterparty = msg.sender;
        
        // Interactions (events)
        emit WagerAccepted(wagerId, msg.sender);
    }
    
    function resolveWager(bytes32 wagerId) external {
        // Checks
        Wager storage wager = wagers[wagerId];
        require(!wager.resolved, "Already resolved");
        require(block.timestamp > wager.deadline, "Too early");
        require(wager.counterparty != address(0), "Not accepted");
        
        // Interactions with oracle
        oracle.requestResolution(wagerId, wager.topic, wager.condition);
    }
    
    function finalizeWager(bytes32 wagerId) external {
        // Checks
        Wager storage wager = wagers[wagerId];
        require(!wager.resolved, "Already resolved");
        (bool processed, bool result) = oracle.getResolution(wagerId);
        require(processed, "Not processed by oracle");
        
        // Effects
        wager.resolved = true;
        wager.creatorWins = result;
        address winner = result ? wager.creator : wager.counterparty;
        uint256 payout = wager.amount * 2;
        
        // Interactions
        (bool success, ) = payable(winner).call{value: payout}("");
        require(success, "Transfer failed");
        emit WagerResolved(wagerId, winner);
    }
}
