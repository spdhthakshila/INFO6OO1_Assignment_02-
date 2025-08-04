// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CityParkingToken.sol";

// Manages parking spots and token rewards in a smart city
contract SmartCityParking {
    address public cityAuthority; // Stores the address of the city authority
    CityParkingToken public parkingToken; // Links to the token contract

    struct Driver {
        string name; // Driver's name
        bool isRegistered; // Tracks if the driver is registered
    }

    struct ParkingSpot {
        uint256 id; // Unique identifier for the spot
        string location; // Where the spot is located
        bool isAvailable; // Shows if the spot is free
        address occupant; // The address of the driver using the spot
    }

    mapping(address => Driver) public drivers; // Maps addresses to driver details
    mapping(uint256 => ParkingSpot) public parkingSpots; // Maps spot IDs to spot details

    event DriverRegistered(address indexed driver, string name); // Logs when a driver registers
    event ParkingSpotAdded(uint256 indexed id, string location); // Logs when a new spot is added
    event SpotReserved(address indexed driver, uint256 indexed spotId); // Logs when a spot is reserved
    event SpotReleased(address indexed driver, uint256 indexed spotId); // Logs when a spot is released
    event PaymentMade(address indexed driver, uint256 indexed spotId, uint256 amount); // Logs when payment is made
    event RewardIssued(address indexed driver, uint256 amount); // Logs when a reward is given

    constructor(address _parkingTokenAddress) {
        // Sets up the contract when deployed
        cityAuthority = msg.sender; // Sets the deployer as the authority
        parkingToken = CityParkingToken(_parkingTokenAddress); // Links to the token contract
    }

   function registerDriver(string memory _name) public {
        // Defines a public function to allow drivers to register with a name
        require(!drivers[msg.sender].isRegistered, "Already registered");
        // Checks that the caller (msg.sender) is not already registered, reverts with "Already registered" if true
        require(bytes(_name).length > 0, "Name required");
        // Checks that the provided name is not empty, reverts with "Name required" if true
        drivers[msg.sender] = Driver(_name, true); // Creates a new Driver struct with the name and sets isRegistered to true for the caller
        emit DriverRegistered(msg.sender, _name); // Emits the DriverRegistered event with the caller's address and name
    }

    function addParkingSpot(uint256 _id, string memory _location) public {
        // Defines a public function to allow the city authority to add a parking spot
        require(msg.sender == cityAuthority, "Only authority");
        // Checks that the caller is the cityAuthority, reverts with "Only authority" if false
        require(parkingSpots[_id].id == 0, "Spot exists");
        // Checks that no spot with the given _id exists, reverts with "Spot exists" if false
        require(bytes(_location).length > 0, "Location required");
        // Checks that the location is not empty, reverts with "Location required" if true
        parkingSpots[_id] = ParkingSpot(_id, _location, true, address(0));
        // Creates a new ParkingSpot struct with the given id, location, sets it as available, and no occupant
        emit ParkingSpotAdded(_id, _location); // Emits the ParkingSpotAdded event with the id and location
    }

    function reserveSpot(uint256 _spotId) public {
        // Defines a public function to allow a registered driver to reserve a spot
        require(drivers[msg.sender].isRegistered, "Register first");
        // Checks that the caller is registered, reverts with "Register first" if false
        require(parkingSpots[_spotId].id != 0, "Spot not found");
        // Checks that a spot with the given _spotId exists, reverts with "Spot not found" if false
        require(parkingSpots[_spotId].isAvailable, "Spot taken");
        // Checks that the spot is available, reverts with "Spot taken" if false
        parkingSpots[_spotId].isAvailable = false; // Marks the spot as unavailable
        parkingSpots[_spotId].occupant = msg.sender; // Sets the caller as the occupant of the spot
        emit SpotReserved(msg.sender, _spotId); // Emits the SpotReserved event with the caller's address and spot ID
    }

    function releaseSpot(uint256 _spotId) public {
        // Defines a public function to allow a driver to release a spot and earn a reward
        require(parkingSpots[_spotId].id != 0, "Spot not found");
        // Checks that a spot with the given _spotId exists, reverts with "Spot not found" if false
        require(parkingSpots[_spotId].occupant == msg.sender, "Not your spot");
        // Checks that the caller is the current occupant, reverts with "Not your spot" if false
        parkingSpots[_spotId].isAvailable = true; // Marks the spot as available
        parkingSpots[_spotId].occupant = address(0); // Clears the occupant
        uint256 rewardAmount = 10 * 10 ** 18; // Calculates the reward amount as 10 tokens (with 18 decimals)
        parkingToken.reward(msg.sender, rewardAmount); // Calls the reward function on the token contract to send the reward to the caller
        emit SpotReleased(msg.sender, _spotId); // Emits the SpotReleased event with the caller's address and spot ID
        emit RewardIssued(msg.sender, rewardAmount); // Emits the RewardIssued event with the caller's address and reward amount
    }

    function payForParking(uint256 _spotId, uint256 _amount) public {
        // Defines a public function to allow a driver to pay for a reserved spot
        require(parkingSpots[_spotId].id != 0, "Spot not found");
        // Checks that a spot with the given _spotId exists, reverts with "Spot not found" if false
        require(parkingSpots[_spotId].occupant == msg.sender, "Not your spot");
        // Checks that the caller is the current occupant, reverts with "Not your spot" if false
        require(_amount > 0, "Amount required");
        // Checks that the payment amount is greater than zero, reverts with "Amount required" if false
        parkingToken.transferFrom(msg.sender, cityAuthority, _amount);
        // Transfers the specified amount of tokens from the caller to the cityAuthority using the token contract
        emit PaymentMade(msg.sender, _spotId, _amount); // Emits the PaymentMade event with the caller's address, spot ID, and amount
    }
}