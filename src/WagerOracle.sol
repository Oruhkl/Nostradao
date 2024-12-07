// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title WagerOracle - Oracle contract for resolving wagers
/// @notice Provides external data verification for betting outcomes
contract WagerOracle {
    // === State Variables ===
    address public owner;
    address public wagerContract;
    
    struct Resolution {
        bool isProcessed;
        bool result;
        string dataSource1;
        string dataSource2;
    }
    
    mapping(bytes32 => Resolution) public resolutions;
    
    // === Events ===
    event ResolutionRequested(
        bytes32 indexed wagerId,
        string topic,
        string condition,
        uint256 timestamp
    );
    
    event ResolutionProvided(
        bytes32 indexed wagerId,
        bool result,
        string dataSource1,
        string dataSource2
    );
    
    // === Modifiers ===
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    modifier onlyWagerContract() {
        require(msg.sender == wagerContract, "Only wager contract can call");
        _;
    }
    
    // === Constructor ===
    constructor() {
        owner = msg.sender;
    }
    
    // === External Functions ===
    function setWagerContract(address _wagerContract) external onlyOwner {
        // Effects
        wagerContract = _wagerContract;
    }
    
    function requestResolution(
        bytes32 wagerId,
        string calldata topic,
        string calldata condition
    ) external onlyWagerContract {
        // Checks
        require(!resolutions[wagerId].isProcessed, "Already processed");
        
        // Interactions (events)
        emit ResolutionRequested(wagerId, topic, condition, block.timestamp);
    }
    
    function provideResolution(
        bytes32 wagerId,
        bool result,
        string calldata dataSource1,
        string calldata dataSource2
    ) external onlyOwner {
        // Checks
        require(!resolutions[wagerId].isProcessed, "Already processed");
        
        // Effects
        resolutions[wagerId] = Resolution(true, result, dataSource1, dataSource2);
        
        // Interactions (events)
        emit ResolutionProvided(wagerId, result, dataSource1, dataSource2);
    }
    
    // === View Functions ===
    function getResolution(bytes32 wagerId) external view returns (bool, bool) {
        Resolution memory resolution = resolutions[wagerId];
        return (resolution.isProcessed, resolution.result);
    }
}
