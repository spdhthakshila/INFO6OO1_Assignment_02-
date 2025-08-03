// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// Import CityParkingToken.sol (ensure it’s in the same directory and compiled first)
import "./CityParkingToken.sol";

// Smart City Parking System for urban mobility
// Tested in Remix VM (Prague) with Solidity 0.8.30
contract SmartCityParking {
    // City authority (admin, set to contract deployer)
    address public cityAuthority;
    // Reference to CityParkingToken contract
    CityParkingToken public parkingToken;

    // Struct for Driver (citizen)
    struct Driver {
        string name; // Driver's name
        bool isRegistered; // Registration status
    }

    // Struct for Parking Spot (service point)
    struct ParkingSpot {
        uint256 id; // Unique spot ID
        string location; // Location (e.g., "City Center Lot A")
        bool isAvailable; // Availability status
        address occupant; // Current driver occupying the spot
    }

    // Mappings to store data
    mapping(address => Driver) public drivers; // Map address to Driver
    mapping(uint256 => ParkingSpot) public parkingSpots; // Map spot ID to ParkingSpot

    // Events for transparency
    event DriverRegistered(address indexed driver, string name);
    event ParkingSpotRegistered(uint256 indexed id, string location);
    event SpotReserved(address indexed driver, uint256 indexed spotId);
    event SpotReleased(uint256 indexed spotId);
    event ParkingPaid(address indexed driver, uint256 indexed spotId, uint256 amount);

    // Modifier to restrict to city authority
    modifier onlyCityAuthority() {
        require(msg.sender == cityAuthority, "Only city authority can perform this action");
        _;
    }

    // Modifier to restrict to registered drivers
    modifier onlyRegistered() {
        require(drivers[msg.sender].isRegistered, "Driver not registered");
        _;
    }

    // Constructor sets deployer as city authority and links token contract
    constructor(address _parkingTokenAddress) {
        cityAuthority = msg.sender;
        parkingToken = CityParkingToken(_parkingTokenAddress);
    }

    // Register a new driver (citizen)
    function registerDriver(string memory _name) public {
        require(!drivers[msg.sender].isRegistered, "Driver already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");

        drivers[msg.sender] = Driver(_name, true);
        emit DriverRegistered(msg.sender, _name);
    }

    // Register a new parking spot (city authority only)
    function registerParkingSpot(uint256 _id, string memory _location) public onlyCityAuthority {
        require(parkingSpots[_id].id == 0, "Parking spot already exists");
        require(bytes(_location).length > 0, "Location cannot be empty");

        parkingSpots[_id] = ParkingSpot(_id, _location, true, address(0));
        emit ParkingSpotRegistered(_id, _location);
    }

    // Reserve a parking spot
    function reserveSpot(uint256 _spotId) public onlyRegistered {
        require(parkingSpots[_spotId].id != 0, "Parking spot does not exist");
        require(parkingSpots[_spotId].isAvailable, "Parking spot is not available");

        parkingSpots[_spotId].isAvailable = false;
        parkingSpots[_spotId].occupant = msg.sender;
        emit SpotReserved(msg.sender, _spotId);
    }

    // Release a parking spot
    function releaseSpot(uint256 _spotId) public onlyRegistered {
        require(parkingSpots[_spotId].id != 0, "Parking spot does not exist"); // Fixed: Changed _id to _spotId
        require(parkingSpots[_spotId].occupant == msg.sender, "Not your spot");

        parkingSpots[_spotId].isAvailable = true;
        parkingSpots[_spotId].occupant = address(0);
        emit SpotReleased(_spotId);
    }

    // Pay for parking with tokens
    function payForParking(uint256 _spotId, uint256 _amount) public onlyRegistered {
        require(parkingSpots[_spotId].id != 0, "Parking spot does not exist");
        require(parkingSpots[_spotId].occupant == msg.sender, "Not your spot");
        require(_amount > 0, "Payment amount must be greater than zero");

        // Transfer tokens to city authority
        parkingToken.transferFrom(msg.sender, cityAuthority, _amount);
        emit ParkingPaid(msg.sender, _spotId, _amount);
    }
}