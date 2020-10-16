// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './SafeMath.sol';


contract BookingDapp 
{
    using SafeMath for uint256;
    
	address tokenAddress;

	struct OpenEvent 
	{
// 		event details
		address event_owner;
		string event_name;
		uint256 event_id;
		uint256 start_time;
		string event_location;
		uint256 seat_types;
		
// 		price of different types of tickets
		uint256[] prices;
		
// 		bool limited;
		
// 		number of seats of different types
		uint256[] seat_numbers;
		
// 		total number of seats
        uint256 total_seats;
		
// 		event collection wallet
		uint256 wallet;
		
// 		visited array for seats booked
        uint256[2][] booked;
        
//      For having record of seats and person booking them
        // mapping(uint256 => address) record;
        
	}
	
	mapping(uint256 => mapping(uint256 => address)) Record;
	
	OpenEvent[] private openEvents;
	
	uint256[] eventExists;
// 	struct Ticket 
// 	 {
// 		uint event_id;
// 		uint256 seat;
// 	}
	
// 	Ticket[] private tickets;

    event CreatedEvent(address indexed owner, uint256 eventId);
    
    event SoldTicket(address indexed buyer, uint256 indexed eventId, uint256[] seats);
	
    // modifier onlyKycApproved()
    // {
    //     require(kycDappContract.isKycLevel1(msg.sender), 'KYC is not approved');
    //     _;
    // }

    modifier goodTime(uint _time)
    {
        require(_time > block.timestamp);
        _;
    }

    modifier eventExist(uint _id)
    {
        require(eventExists[_id] == 1);
        _;
    }

	function createEvent(string memory _name, uint _time, string memory _location, uint256 _types, uint256[] memory _prices, uint256[] memory _seats) goodTime(_time) public
	{
        uint256[2][] memory _booked;
		uint256[] memory a;
		for(uint256 i=1;i<_types;i++)
		    a[i] += a[i-1];
		
		uint256 seat=1;
		for(uint256 i=0;i<_types;i++)
		{
		    while(seat<=a[i])
		    {
		        _booked[seat][0] = 0;
		        _booked[seat][1] = i+1;
		        seat++;
		    }
		}
		
		OpenEvent memory _event = OpenEvent({
			event_owner: msg.sender,
			event_name: _name,
			event_id: openEvents.length,
			start_time: _time,
			event_location: _location,
// 			limited: _limited,
            seat_types: _types,
            prices: _prices,
            seat_numbers: _seats,
            total_seats: a[_types-1],
            wallet: 0,
            booked: _booked
		});
		
		openEvents.push(_event);
		eventExists[openEvents.length-1] = 1;
		emit CreatedEvent(msg.sender, openEvents.length-1);
	}

	function getEvent(uint _id) public view eventExist(_id) returns(address, string memory, uint256, uint256, string memory, uint256, uint256[] memory, uint256[] memory, uint256, uint256[2][] memory)
	{
	    OpenEvent memory _event = openEvents[_id];
	    return(
		    _event.event_owner,
		    _event.event_name,
		    _event.event_id,
		    _event.start_time,
		    _event.event_location,
		    _event.seat_types,
		    _event.prices,
		    _event.seat_numbers,
		    _event.wallet,
		    _event.booked
	    );
	}

	function getEventsCount() public view returns(uint) {
		return openEvents.length;
	}
	
	// Function to buy ticket to specific event.
	
	function buyTicket(uint _eventId, uint[] memory seatno, uint256 amt) public payable eventExist(_eventId) /*goodTime(openEvents[_eventId].start_time)*/
	{
	    OpenEvent memory _event = openEvents[_eventId];
	    
	    uint check=0;
		for(uint256 i=0;i<seatno.length;i++)
		{
		    if(_event.seat_numbers[_event.booked[seatno[i]][1] - 1]>0 || _event.booked[seatno[i]][0] == 1)
		    {
		        check=1;
		        break;
		    }
		}
		
		require(check==0, "Seats selected have been booked");
		
		require(msg.value == amt, "Require price of tickets");
		
		for(uint256 i=0;i<seatno.length;i++)
		{
		    _event.booked[seatno[i]][0]=1;
		    _event.seat_numbers[_event.booked[seatno[i]][1] - 1] -= 1;
		  //  _event.record[seatno[i]] = msg.sender;
		    Record[_eventId][seatno[i]] = msg.sender;
		}
		
		_event.wallet += amt;
		

		emit SoldTicket(msg.sender, _eventId, seatno);
	}
	
// 	function getTicket(uint _id) public view returns(uint, uint) 
// 	{
// 		require(_id < tickets.length);
// 		Ticket memory _ticket = tickets[_id];
// 		return(_ticket.event_id, _ticket.seat);
// 	}
	
	function cancelTicket(uint _eventId, uint[] memory seatno, uint _time) eventExist(_eventId) public payable
	{
	    
	    OpenEvent memory _event = openEvents[_eventId];
	    
	    //Ticket cannot be cancelled once the event has started 
	    require(_time>=_event.start_time, "Cannot cancel the ticket, event has started!");
	    

	    //80% of the ticket price refunded back when ticket is cancelled within 48 hours before the event
	    //100% ticket price refunded if ticket cancelled before 48 hours of the event 
	    
	    if( _event.start_time - block.timestamp <= 48*3600)
	    {
	        for(uint256 i=0;i<seatno.length;i++)
	        {
    	        _event.wallet -= (_event.prices[_event.booked[seatno[i]][1] - 1]).mul(80).div(100);
    	        _event.booked[seatno[i]][0]=0;
    		    _event.seat_numbers[_event.booked[seatno[i]][1] - 1] += 1;
    		  //  _event.record[seatno[i]] = address(0);
    		    Record[_eventId][seatno[i]] = address(0);
	        }
	    }
	    else
	    {
	        for(uint256 i=0;i<seatno.length;i++)
	        {
    	        _event.wallet -= _event.prices[_event.booked[seatno[i]][1] - 1];
    	        _event.booked[seatno[i]][0]=0;
    		    _event.seat_numbers[_event.booked[seatno[i]][1] - 1] += 1;
    		  //  _event.record[seatno[i]] = address(0);
    		    Record[_eventId][seatno[i]] = address(0);

	        }
	    }
	   
       
        // delete tickets[_seatno];

	}
	
	function cancelEvent(uint _eventId) public eventExist(_eventId)
	{
       OpenEvent memory _event = openEvents[_eventId];
       
	   eventExists[_eventId] = 0;
	   
	   for(uint256 i=1;i<_event.total_seats;i++)
	   {
	       if(Record[_eventId][i] != address(0))
	       {
	           _event.wallet -= _event.prices[_event.booked[i][1] - 1];
	       }
	   }
	}
}