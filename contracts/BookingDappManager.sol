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
    uint256 eventId = 0;
    
    event NewEvent(uint256, address, address);
    
    constructor()
    {
        owner = msg.sender;
    }
    
    
    function createEvent(string memory _name, string memory _location, uint256 _startTime, uint256 _seatTypes, uint256[] memory _seatsPerType, uint256[] memory _pricePerType) public
    {
        uint256 totalSeats = 0;
        for(uint256 i=0; i<_seatTypes; i++)
            totalSeats += _seatsPerType[i];
        
        eventId++;
        
        EventManager _newEvent = new EventManager(
            msg.sender,
            _name,
            _location,
            _startTime,
            _seatTypes,
            _seatsPerType,
            _pricePerType,
            totalSeats
        );
        
        events[address(_newEvent)] = true;
        
        emit NewEvent(eventId, address(_newEvent), msg.sender);
    }
    
}