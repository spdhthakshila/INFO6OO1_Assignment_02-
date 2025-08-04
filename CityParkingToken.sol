// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic ERC20-like token for City Parking System
contract CityParkingToken {
    string public name = "City Parking Token"; // Sets the token's name
    string public symbol = "CPT"; // Sets the token's symbol
    uint8 public decimals = 18; // Sets decimal places for token amounts (standard is 18)
    uint256 public totalSupply; // Tracks the total number of tokens
    mapping(address => uint256) public balanceOf; // Stores how many tokens each address has
    mapping(address => mapping(address => uint256)) public allowance; // Tracks how many tokens an address allows another to spend

    event Transfer(address indexed from, address indexed to, uint256 value); // Logs when tokens are transferred
    event Approval(address indexed owner, address indexed spender, uint256 value); // Logs when spending approval is set

    constructor(uint256 _initialSupply) {
        // Creates the initial tokens and gives them to the person deploying the contract
        totalSupply = _initialSupply * 10 ** uint256(decimals); // Calculates total supply with decimals
        balanceOf[msg.sender] = totalSupply; // Assigns all tokens to the deployer
        emit Transfer(address(0), msg.sender, totalSupply); // Records the minting as a transfer from zero address
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Allows a user to send tokens to another address
        require(_to != address(0), "Invalid address"); // Checks the destination address is valid
        require(balanceOf[msg.sender] >= _value, "Insufficient balance"); // Ensures the sender has enough tokens
        balanceOf[msg.sender] -= _value; // Subtracts tokens from the sender
        balanceOf[_to] += _value; // Adds tokens to the receiver
        emit Transfer(msg.sender, _to, _value); // Logs the transfer
        return true; // Confirms the transfer worked
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // Allows another address to spend tokens on behalf of the owner
        allowance[msg.sender][_spender] = _value; // Sets the allowed amount
        emit Approval(msg.sender, _spender, _value); // Logs the approval
        return true; // Confirms the approval worked
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // Allows an approved address to transfer tokens from another address
        require(_to != address(0), "Invalid address"); // Checks the destination is valid
        require(balanceOf[_from] >= _value, "Insufficient balance"); // Ensures the sender has enough tokens
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance"); // Checks if enough is approved
        balanceOf[_from] -= _value; // Subtracts tokens from the sender
        balanceOf[_to] += _value; // Adds tokens to the receiver
        allowance[_from][msg.sender] -= _value; // Reduces the approved amount
        emit Transfer(_from, _to, _value); // Logs the transfer
        return true; // Confirms the transfer worked
    }

    // Reward function for drivers (called by SmartCityParking)
    function reward(address _to, uint256 _value) public {
        // Gives a reward in tokens to a driver for good behavior
        require(msg.sender == address(parkingContract), "Only parking contract"); // Ensures only the parking contract can reward
        require(balanceOf[address(this)] >= _value, "Insufficient contract balance"); // Checks if the contract has enough tokens
        balanceOf[address(this)] -= _value; // Subtracts tokens from the contract
        balanceOf[_to] += _value; // Adds tokens to the driver
        emit Transfer(address(this), _to, _value); // Logs the reward as a transfer
    }

    // Reference to SmartCityParking for reward authorization
    address private parkingContract; // Stores the address of the parking contract

    // Set parking contract address (called by city authority)
    function setParkingContract(address _parkingContract) public {
        require(msg.sender == cityAuthority, "Only authority can set parking contract"); // Only the city authority can set or change the parking contract
        parkingContract = _parkingContract; // Updates the parking contract address
    }

    // City authority (deployer)
    address private cityAuthority = msg.sender; // Stores the address of the person who deployed the contract
}
