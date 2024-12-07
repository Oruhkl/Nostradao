// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Market.sol";

/// @title Nostradao - Prediction market factory and registry
/// @notice Creates and tracks prediction markets
contract Nostradao {
    // === State Variables ===
    enum Category { Sports, Politics, Entertainment, Other }
    
    struct User {
        address userAddress;
        string name;
    }
    
    struct MarketInfo {
        address marketAddress;
        Category category;
    }
    
    mapping(address => User) public users;
    MarketInfo[] public marketInfos;
    
    address public oracle;
    address public feeCollector;
    
    // === Events ===
    event MarketCreated(address indexed market, string description, Category category);
    event UserRegistered(address indexed user, string name);
    
    constructor(address _oracle, address _feeCollector) {
        oracle = _oracle;
        feeCollector = _feeCollector;
    }
    
    // === External Functions ===
    function registerUser(string memory name) external {
        // Checks
        require(users[msg.sender].userAddress == address(0), "User already registered");
        
        // Effects
        users[msg.sender] = User(msg.sender, name);
        
        // Interactions (events)
        emit UserRegistered(msg.sender, name);
    }
    
    function createMarket(
        string memory description,
        string[] memory outcomes,
        uint256 bettingDeadline,
        Category category
    ) external {
        Market newMarket = new Market(
            msg.sender,
            description,
            outcomes,
            bettingDeadline,
            oracle,
            feeCollector
        );
        
        marketInfos.push(MarketInfo(address(newMarket), category));
        emit MarketCreated(address(newMarket), description, category);
    }
    
    // === View Functions ===
    function getMarketsByCategory(Category _category) external view returns (address[] memory) {
        // Count markets in category
        uint256 count = 0;
        for(uint i = 0; i < marketInfos.length; i++) {
            if(marketInfos[i].category == _category) {
                count++;
            }
        }
        
        // Create filtered array
        address[] memory filtered = new address[](count);
        uint256 index = 0;
        for(uint i = 0; i < marketInfos.length; i++) {
            if(marketInfos[i].category == _category) {
                filtered[index] = marketInfos[i].marketAddress;
                index++;
            }
        }
        return filtered;
    }
    
    function getAllMarkets() external view returns (address[] memory) {
        address[] memory allMarkets = new address[](marketInfos.length);
        for(uint i = 0; i < marketInfos.length; i++) {
            allMarkets[i] = marketInfos[i].marketAddress;
        }
        return allMarkets;
    }
}