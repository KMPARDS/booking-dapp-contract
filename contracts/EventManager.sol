// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';


contract EventManager 
{
    using SafeMath for uint256;
    
    address public eventOwner;
    string public eventName;
    string public eventLocation;
    uint256 public eventStartTime;
    uint256 public seatTypes;
    uint256[] public seatsPerType;
    uint256[] public pricePerType;
    uint256 public totalSeats;
    uint256 public wallet;
    
    uint256[] temp; // public not needed
    bool public eventStatus;
    
    mapping(uint256 => bool) public seatStatus;
    mapping(uint256 => uint256) public seatTypeId;
    mapping(uint256 => address) public seatOwner;
    
    event SoldTicket(address indexed buyer, uint256[] seats);
    event CancelledTicket(address indexed buyer, uint256[] seats);
    
    
    modifier onlyOwner()
    {
        require(msg.sender == eventOwner, "Only event owner can cancel event");
        _;
    }
    
    
    modifier eventExists()
    {
        require(eventStatus == true, "Event does not exist");
        _;
    }
    
    
    constructor(address _eventOwner, string memory _name, string memory _location, uint256 _startTime, uint256 _seatTypes, uint256[] memory _seatsPerType, uint256[] memory _pricePerType, uint256 _totalSeats)
    {
        eventOwner = _eventOwner;
        eventName = _name;
        eventLocation = _location;
        eventStartTime = _startTime;
        seatTypes = _seatTypes;
        seatsPerType = _seatsPerType;
        pricePerType = _pricePerType;
        totalSeats = _totalSeats;
        wallet = 0;
        
        temp = seatsPerType;
        
        for(uint256 i=1; i<seatTypes; i++)
            temp[i] += temp[i-1];
            
        uint256 seatNo = 1;
        for(uint256 i=0; i<seatTypes; i++)
        {
            while(seatNo <= temp[i])
            {
                seatStatus[seatNo] = true;
                seatTypeId[seatNo] = i;
                seatNo++;
            }
        }
        
        eventStatus = true;
    }
    
    
    function buyTicket(uint256[] memory seatNo/*, uint256 amt*/) eventExists public payable
    {
        bool check = true;
        uint256 amt = 0;
        
        for(uint256 i=0; i<seatNo.length; i++)
        {
            if(seatStatus[seatNo[i]] == false || seatNo[i]>totalSeats)
            {
                check = false;
                break;
            }
            
            amt += pricePerType[seatTypeId[seatNo[i]]];
            
        }
        
        require(check == true, "Seats selected are not available");
        require(amt == msg.value, "Insufficient amount for buying tickets");
        
        for(uint256 i=0; i<seatNo.length; i++)
        {
            seatStatus[seatNo[i]] = false;
            seatsPerType[seatTypeId[seatNo[i]]] -= 1;
            seatOwner[seatNo[i]] = msg.sender;
        }
        
        wallet += amt;
        
        emit SoldTicket(msg.sender, seatNo);
    }
    
    
    function cancelTicket(uint256[] memory seatNo) eventExists public payable
    {
        bool check1 = true;
        uint256 amt = 0;
        
        for(uint256 i=0;i<seatNo.length;i++)
        {
            if(seatOwner[seatNo[i]] != msg.sender)
            {
                check1 = false;
                break;
            }
        }
        
        require(check1 == true, "You cannot cancel tickets you haven't bought");
        
        // Considering for now the whole amount being refunded
        for(uint256 i=0; i<seatNo.length; i++)
        {
            seatStatus[seatNo[i]] = true;
            seatsPerType[seatTypeId[seatNo[i]]] += 1;
            seatOwner[seatNo[i]] = address(0);
            
            amt += pricePerType[seatTypeId[seatNo[i]]];
        }
        
        wallet -= amt;
        
        payable(msg.sender).transfer(amt);
        
        emit CancelledTicket(msg.sender, seatNo);
    }
    
    
    function cancelEvent() onlyOwner eventExists public payable
    {
        for(uint256 i=1;i<=totalSeats;i++)
        {
            if(seatOwner[i] != address(0))
            {
                payable(seatOwner[i]).transfer(pricePerType[seatTypeId[i]]);
                wallet -= pricePerType[seatTypeId[i]];
            }
        }
        
        require(wallet == 0, "All refunds not made");
        
        eventStatus = false;
    }
}