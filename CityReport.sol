// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Smart City Reporting System
/// @author 
/// @notice Citizens can register and submit city issue reports
contract SmartCityReportSystem {

    // ====== STRUCTS ======
    struct Citizen {
        string name;
        uint idNumber;
        bool isRegistered;
    }

    struct Report {
        string description;
        uint timestamp;
    }

    // ====== STATE VARIABLES ======
    mapping(address => Citizen) public citizens;
    mapping(address => Report[]) public reports;
    mapping(address => uint) public reportPoints;

    // ====== EVENTS ======
    event CitizenRegistered(address indexed user, string name, uint idNumber);
    event ReportSubmitted(address indexed user, string description, uint timestamp);
    event PointsAwarded(address indexed user, uint totalPoints);

    // ====== MODIFIERS ======
    modifier onlyRegisteredCitizen() {
        require(citizens[msg.sender].isRegistered, "You must be registered to perform this action.");
        _;
    }

    // ====== FUNCTIONS ======

    /// @notice Register a citizen (only once)
    function registerCitizen(string memory _name, uint _idNumber) public {
        require(!citizens[msg.sender].isRegistered, "Already registered.");
        citizens[msg.sender] = Citizen(_name, _idNumber, true);

        emit CitizenRegistered(msg.sender, _name, _idNumber);
    }

    /// @notice Submit a city issue report
    function submitReport(string memory _description) public onlyRegisteredCitizen {
        reports[msg.sender].push(Report({
            description: _description,
            timestamp: block.timestamp
        }));

        // Optional: Give 1 point per report
        reportPoints[msg.sender] += 1;

        emit ReportSubmitted(msg.sender, _description, block.timestamp);
        emit PointsAwarded(msg.sender, reportPoints[msg.sender]);
    }

    /// @notice Get number of reports submitted by a user
    function getReportCount(address _user) public view returns (uint) {
        return reports[_user].length;
    }

    /// @notice Get a specific report by index
    function getReportByIndex(address _user, uint index) public view returns (string memory, uint) {
        require(index < reports[_user].length, "Invalid report index");
        Report memory r = reports[_user][index];
        return (r.description, r.timestamp);
    }
}
