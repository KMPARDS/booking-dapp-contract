pragma solidity ^0.6.11;

import './KycDapp.sol';
import './daySwappers.sol';

/**
* Title OpenEvents
* It is a main contract that provides ability to create events and view information about events. 
*It is a main contract that provides ability to buy tickets and view tickets.
*It is a main contract that provides ability cancel tickets and events.
*/

contract OpenEvents {
	address tokenAddress;

	struct OpenEvent {
		
		//event details
		address owner;
		string name;
		uint time;
		
		//different types of tickets
		uint price_front;
		uint price_centre;
		uint price_back;
		
		bool limited;
		uint seats;
		uint sold;
		uint wallet;
	}
	
	OpenEvent[] private openEvents;
	
	struct Ticket {
		uint event_id;
		uint seat;
	}
	
	Ticket[] private tickets;

    event CreatedEvent(address indexed owner, uint eventId);
    
    event SoldTicket(address indexed buyer, uint indexed eventId);
	
    modifier onlyKycApproved()
    {
        require(kycDappContract.isKycLevel1(msg.sender), 'KYC is not approved');
        _;
    }

    modifier goodTime(uint _time)
    {
        require(_time > now);
        _;
    }

    modifier eventExist(uint _id)
    {
        require(_id < openEvents.length);
        _;
    }

	function createEvent(string memory _name, uint _time, 	uint _price_front, uint _price_centre, uint _price_back, bool _limited, uint _seats) goodTime(_time) public
	{
		OpenEvent memory _event = OpenEvent({
			owner: msg.sender,
			name: _name,
			time: _time,
			limited: _limited,
	        price_front: _price_front,
		    price_centre: _price_centre,
		    price_back: _price_back,
			seats: _seats,
			sold: 0,
			wallet: 0
		});
		openEvents.push(_event);
		uint _eventid= openEvents.length;
		emit CreatedEvent(msg.sender, _eventid);
	}

	function getEvent(uint _id) public view eventExist(_id) returns(string memory name,	uint time,	uint price_front,uint price_centre, uint price_back, bool limited, uint seats, uint sold, address owner, uint wallet)
		{
		    OpenEvent memory _event = openEvents[_id];
		    return(
			    _event.name,
			    _event.time,
			    _event.price_front,
			    _event.price_centre,
			    _event.price_back,
			    _event.limited,
			    _event.seats,
			    _event.sold,
			    _event.owner,
			    _event.wallet
		    );
	    }

	function getEventsCount() public view returns(uint) {
		return openEvents.length;
	}
	
	// Function to buy ticket to specific event.
	
	function buyTicket(uint _eventId, uint seatno) public payable eventExist(_eventId) goodTime(openEvents[_eventId].time)
	{
		require(openEvents[_eventId].price_front == msg.value, "Front seat booked");
		require(openEvents[_eventId].price_centre == msg.value, "Centre seat booked");
		require(openEvents[_eventId].price_back == msg.value, "Back seat booked");
		
		openEvents[_eventId].wallet += msg.value;
	
	    uint _seat = openEvents[_eventId].sold + 1 ;
	    openEvents[_eventId].sold = _seat;
		
		Ticket memory _ticket = Ticket({
			event_id: _eventId,
			seat: seatno
		});

		emit SoldTicket(msg.sender, _eventId);
	}
	
	function getTicket(uint _id) public view returns(uint, uint) 
	{
		require(_id < tickets.length);
		Ticket memory _ticket = tickets[_id];
		return(_ticket.event_id, _ticket.seat);
	}
	
	function cancelTicket(uint _eventid, uint _seatno, uint _time) public payable
	{
	    
	    //Ticket cannot be cancelled once the event has started 
	    require(_time>now, "Cannot cancel the ticket, event has started!");
	    
	    uint wallet_ = openEvents[_eventid].wallet;
	   
	    //80% of the ticket price refunded back when ticket is cancelled within 48 hours before the event
	    //100% ticket price refunded if ticket cancelled before 48 hours of the event 
	    
	    if( openEvents[_eventid].time - now <48 && msg.value== openEvents[_eventid].price_front)
	        openEvents[_eventid].wallet = wallet_ - ((openEvents[_eventid].price_front*80)/100);
	   
	    else if(openEvents[_eventid].time - now > 48  && msg.value== openEvents[_eventid].price_front) 
	        openEvents[_eventid].wallet = wallet_ - (openEvents[_eventid].price_front);
	    
	    if(openEvents[_eventid].time - now < 48 && msg.value== openEvents[_eventid].price_centre)
	        openEvents[_eventid].wallet = wallet_ - ((openEvents[_eventid].price_centre*80)/100);
	   
	    else if(openEvents[_eventid].time - now > 48 && msg.value== openEvents[_eventid].price_centre)
	        openEvents[_eventid].wallet = wallet_ - (openEvents[_eventid].price_centre);
	   
	    if(openEvents[_eventid].time - now < 48 && msg.value== openEvents[_eventid].price_back)
	        openEvents[_eventid].wallet = wallet_ - ((openEvents[_eventid].price_back*80)/100);
	   
	    else if(openEvents[_eventid].time - now > 48 && msg.value== openEvents[_eventid].price_centre)
	        openEvents[_eventid].wallet = wallet_ - (openEvents[_eventid].price_back);
       
        openEvents[_eventid].sold -= 1;
        delete tickets[_seatno];

	}
	
	function cancelevent(uint _eventid) public goodTime(openEvents[_eventid].time)
	{
	   delete openEvents[_eventid];
	}
}