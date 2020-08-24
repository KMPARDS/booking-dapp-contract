pragma solidity ^0.6.11;

/**
* Title OpenEvents
* It is a main contract that provides ability to create events and view information about events 
*/

contract OpenEvents {
	address tokenAddress;

	struct OpenEvent {
		address owner;
		string name;
		uint time;
		uint price;
		bool limited;
		uint seats;
		uint sold;
	}
	
	OpenEvent[] private openEvents;
	
	struct Ticket {
		uint event_id;
		uint seat;
	}
	
	Ticket[] private tickets;

    event CreatedEvent(address indexed owner, uint eventId);
    event SoldTicket(address indexed buyer, uint indexed eventId);
	
	/*constructor(address _token) public {
		tokenAddress = _token;
	} */

    modifier goodTime(uint _time) {
        require(_time > now);
        _;
    }

    modifier eventExist(uint _id) {
        require(_id < openEvents.length);
        _;
    }

	function createEvent(string memory _name, uint _time, uint _price, bool _limited, uint _seats) goodTime(_time) public
	{
		OpenEvent memory _event = OpenEvent({
			owner: msg.sender,
			name: _name,
			time: _time,
			limited: _limited,
			price: _price,
			seats: _seats,
			sold: 0
		});
		openEvents.push(_event);
		uint _eventid= openEvents.length;
		emit CreatedEvent(msg.sender, _eventid);
	}

	function getEvent(uint _id) public view eventExist(_id) returns(string memory name,	uint time, uint price, bool limited, uint seats, uint sold, address owner)
		{
		    OpenEvent memory _event = openEvents[_id];
		    return(
			    _event.name,
			    _event.time,
			    _event.price,
			    _event.limited,
			    _event.seats,
			    _event.sold,
			    _event.owner
		    );
	    }

	function getEventsCount() public view returns(uint) {
		return openEvents.length;
	}
	
	// Function to buy ticket to specific event.
	
	function buyTicket(uint _eventId) public payable eventExist(_eventId) goodTime(openEvents[_eventId].time)
	{
		require(openEvents[_eventId].price == msg.value);
		
		OpenEvent memory _event = openEvents[_eventId];

	    uint _seat = _event.sold + 1 ;
	    openEvents[_eventId].sold = _seat;
		
		Ticket memory _ticket = Ticket({
			event_id: _eventId,
			seat: _seat
		});

		emit SoldTicket(msg.sender, _eventId);
	}
	
	function getTicket(uint _id) public view returns(uint, uint) 
	{
		require(_id < tickets.length);
		Ticket memory _ticket = tickets[_id];
		return(_ticket.event_id, _ticket.seat);
	}
	
	function cancelTicket(uint _eventid, uint _seatno) public
	{

        openEvents[_eventid].sold -= 1;
        delete tickets[_seatno];

	}
	
	function cancelevent(uint _eventid) public 
	{
	   delete openEvents[_eventid];
	}
}