// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './EventManager.sol';

contract BookingDappManager 
{
    using SafeMath for uint256;
    
    address public owner;
    mapping(address => bool) public events;
    uint256 public totalEvents = 0;
    
    // address[] public allEvents;

    event NewEvent(uint256, address indexed, address, string, string, uint256);
    event BoughtTickets(address indexed _event, address indexed buyer, uint256[] seats, string name, string location, uint256 startTime);
    event CancelTickets(address indexed _event, address indexed buyer, uint256[] seats, string name, string location, uint256 startTime);
    
    constructor()
    {
        owner = msg.sender;
    }
    
    
    function createEvent(string memory _name, string memory _desc, string memory _location, uint256 _startTime, uint256 _seatTypes, uint256[] memory _seatsPerType, uint256[] memory _pricePerType) public
    {
        uint256 totalSeats = 0;
        for(uint256 i=0; i<_seatTypes; i++)
            totalSeats += _seatsPerType[i];
        
        totalEvents++;
        
        EventManager _newEvent = new EventManager(
            msg.sender,
            _name,
            _desc,
            _location,
            _startTime,
            _seatTypes,
            _seatsPerType,
            _pricePerType,
            totalSeats
        );
        
        events[address(_newEvent)] = true;
        // allEvents.push(address(_newEvent));
        
        emit NewEvent(totalEvents, msg.sender, address(_newEvent), _name, _location, _startTime);
    }
    
    function emitTickets(address buyer, uint256[] memory seats, string memory name, string memory location, uint256 startTime) external
    {
        require(events[msg.sender], "Event does not exist");
        emit BoughtTickets(msg.sender, buyer, seats, name, location, startTime);
    }
    
    function emitCancel(address buyer, uint256[] memory seats, string memory name, string memory location, uint256 startTime) external
    {
        require(events[msg.sender], "Event does not exist");
        emit CancelTickets(msg.sender, buyer, seats, name, location, startTime);
    }
}