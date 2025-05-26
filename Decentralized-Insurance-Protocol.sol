// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Insurance Protocol
 * @dev A parametric insurance system for flight delays with automatic payouts
 * @author Smart Contract Developer
 */
contract Project {
    
    // State variables
    address public owner;
    uint256 public totalPremiumPool;
    uint256 public totalPolicies;
    uint256 public constant PREMIUM_RATE = 0.01 ether; // Fixed premium for simplicity
    uint256 public constant COVERAGE_AMOUNT = 0.1 ether; // Fixed coverage amount
    uint256 public constant POLICY_DURATION = 1 days; // Policy valid for 1 day
    
    // Policy structure
    struct Policy {
        address holder;
        uint256 premium;
        uint256 coverageAmount;
        uint256 startTime;
        uint256 endTime;
        string flightNumber;
        bool active;
        bool claimed;
    }
    
    // Mappings
    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public userPolicies;
    mapping(string => bool) public flightDelayed; // Mock oracle data
    
    // Events
    event PolicyPurchased(uint256 indexed policyId, address indexed holder, string flightNumber);
    event ClaimProcessed(uint256 indexed policyId, address indexed holder, uint256 amount);
    event FlightStatusUpdated(string flightNumber, bool isDelayed);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validPolicy(uint256 _policyId) {
        require(_policyId > 0 && _policyId <= totalPolicies, "Invalid policy ID");
        require(policies[_policyId].active, "Policy is not active");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Purchase Insurance Policy
     * @param _flightNumber The flight number to insure
     * @return policyId The ID of the created policy
     */
    function purchasePolicy(string memory _flightNumber) external payable returns (uint256) {
        require(msg.value == PREMIUM_RATE, "Incorrect premium amount");
        require(bytes(_flightNumber).length > 0, "Flight number cannot be empty");
        
        totalPolicies++;
        uint256 policyId = totalPolicies;
        
        policies[policyId] = Policy({
            holder: msg.sender,
            premium: msg.value,
            coverageAmount: COVERAGE_AMOUNT,
            startTime: block.timestamp,
            endTime: block.timestamp + POLICY_DURATION,
            flightNumber: _flightNumber,
            active: true,
            claimed: false
        });
        
        userPolicies[msg.sender].push(policyId);
        totalPremiumPool += msg.value;
        
        emit PolicyPurchased(policyId, msg.sender, _flightNumber);
        return policyId;
    }
    
    /**
     * @dev Core Function 2: Process Insurance Claim
     * @param _policyId The ID of the policy to claim
     */
    function processClaim(uint256 _policyId) external validPolicy(_policyId) {
        Policy storage policy = policies[_policyId];
        
        require(msg.sender == policy.holder, "Only policy holder can claim");
        require(!policy.claimed, "Policy already claimed");
        require(block.timestamp <= policy.endTime, "Policy has expired");
        require(flightDelayed[policy.flightNumber], "Flight was not delayed");
        require(address(this).balance >= policy.coverageAmount, "Insufficient funds in pool");
        
        policy.claimed = true;
        policy.active = false;
        
        // Transfer coverage amount to policy holder
        payable(policy.holder).transfer(policy.coverageAmount);
        
        emit ClaimProcessed(_policyId, policy.holder, policy.coverageAmount);
    }
    
    /**
     * @dev Core Function 3: Update Flight Status (Mock Oracle Function)
     * @param _flightNumber The flight number to update
     * @param _isDelayed Whether the flight is delayed
     */
    function updateFlightStatus(string memory _flightNumber, bool _isDelayed) external onlyOwner {
        require(bytes(_flightNumber).length > 0, "Flight number cannot be empty");
        
        flightDelayed[_flightNumber] = _isDelayed;
        
        emit FlightStatusUpdated(_flightNumber, _isDelayed);
    }
    
    // Utility functions
    
    /**
     * @dev Get policy details
     * @param _policyId The policy ID to query
     */
    function getPolicyDetails(uint256 _policyId) external view returns (
        address holder,
        uint256 premium,
        uint256 coverageAmount,
        uint256 startTime,
        uint256 endTime,
        string memory flightNumber,
        bool active,
        bool claimed
    ) {
        require(_policyId > 0 && _policyId <= totalPolicies, "Invalid policy ID");
        Policy memory policy = policies[_policyId];
        
        return (
            policy.holder,
            policy.premium,
            policy.coverageAmount,
            policy.startTime,
            policy.endTime,
            policy.flightNumber,
            policy.active,
            policy.claimed
        );
    }
    
    /**
     * @dev Get user's policy IDs
     * @param _user The user address
     */
    function getUserPolicies(address _user) external view returns (uint256[] memory) {
        return userPolicies[_user];
    }
    
    /**
     * @dev Check if flight is delayed
     * @param _flightNumber The flight number to check
     */
    function isFlightDelayed(string memory _flightNumber) external view returns (bool) {
        return flightDelayed[_flightNumber];
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Emergency withdrawal function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    /**
     * @dev Add funds to the insurance pool
     */
    function addFunds() external payable {
        require(msg.value > 0, "Must send positive amount");
        totalPremiumPool += msg.value;
    }
}
