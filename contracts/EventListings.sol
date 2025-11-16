// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./EventProducer.sol";

/**
 * @title EventListings
 * @dev Manages real-world event listings created by event producers
 */
contract EventListings is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Event structure
    struct Event {
        string id;
        string producerId;
        string title;
        string description;
        string venue;
        string location; // Address or location string
        uint256 startTime;
        uint256 endTime;
        uint256 ticketPrice; // Price in wei (or smallest currency unit)
        uint256 maxTickets;
        uint256 ticketsSold;
        uint256 createdAt;
        bool isActive;
        bool isCancelled;
        string imageUri;
        string metadata; // JSON string for additional data
    }

    // Event category enum
    enum EventCategory {
        Concert,
        Party,
        Conference,
        Workshop,
        Festival,
        Sports,
        Theater,
        Other
    }

    // Counters
    Counters.Counter private _eventIds;

    // Contract references
    EventProducer public eventProducer;

    // Mappings
    mapping(string => Event) public events;
    mapping(string => string[]) public producerEvents; // producerId => eventId[]
    mapping(string => EventCategory) public eventCategories; // eventId => category
    mapping(string => bool) public eventExists; // eventId => exists

    // Events
    event EventCreated(
        string indexed eventId,
        string indexed producerId,
        string title,
        EventCategory category,
        uint256 startTime,
        uint256 ticketPrice,
        uint256 timestamp
    );

    event EventUpdated(
        string indexed eventId,
        string title,
        uint256 startTime,
        uint256 timestamp
    );

    event EventCancelled(
        string indexed eventId,
        uint256 timestamp
    );

    event EventActivated(
        string indexed eventId,
        bool isActive,
        uint256 timestamp
    );

    // Modifiers
    modifier eventExistsCheck(string memory eventId) {
        require(eventExists[eventId], "Event does not exist");
        _;
    }

    modifier isEventProducer(string memory eventId) {
        require(
            bytes(events[eventId].producerId).length > 0 &&
            _isProducerOwner(events[eventId].producerId),
            "Not the event producer"
        );
        _;
    }

    modifier validEventId(string memory eventId) {
        require(bytes(eventId).length > 0, "Event ID cannot be empty");
        _;
    }

    /**
     * @dev Constructor
     * @param _eventProducer Address of EventProducer contract
     */
    constructor(address _eventProducer) {
        eventProducer = EventProducer(_eventProducer);
    }

    /**
     * @dev Create a new event listing
     * @param eventId Event ID
     * @param producerId Producer ID
     * @param title Event title
     * @param description Event description
     * @param venue Venue name
     * @param location Event location
     * @param startTime Event start timestamp
     * @param endTime Event end timestamp
     * @param ticketPrice Ticket price in wei
     * @param maxTickets Maximum number of tickets
     * @param category Event category
     * @param imageUri Event image URI
     * @param metadata Additional metadata
     */
    function createEvent(
        string memory eventId,
        string memory producerId,
        string memory title,
        string memory description,
        string memory venue,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        uint256 ticketPrice,
        uint256 maxTickets,
        EventCategory category,
        string memory imageUri,
        string memory metadata
    ) external validEventId(eventId) nonReentrant {
        require(!eventExists[eventId], "Event already exists");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(startTime > block.timestamp, "Start time must be in the future");
        require(endTime > startTime, "End time must be after start time");
        require(maxTickets > 0, "Max tickets must be greater than 0");

        // Verify producer exists and caller is the producer
        EventProducer.Producer memory producer = eventProducer.getProducer(producerId);
        require(producer.walletAddress == msg.sender, "Not the producer owner");
        require(producer.isActive, "Producer is not active");

        _eventIds.increment();

        Event memory newEvent = Event({
            id: eventId,
            producerId: producerId,
            title: title,
            description: description,
            venue: venue,
            location: location,
            startTime: startTime,
            endTime: endTime,
            ticketPrice: ticketPrice,
            maxTickets: maxTickets,
            ticketsSold: 0,
            createdAt: block.timestamp,
            isActive: true,
            isCancelled: false,
            imageUri: imageUri,
            metadata: metadata
        });

        events[eventId] = newEvent;
        eventExists[eventId] = true;
        eventCategories[eventId] = category;
        producerEvents[producerId].push(eventId);

        // Update producer stats
        eventProducer.updateProducerStats(producerId, 1, 0, 0);

        emit EventCreated(eventId, producerId, title, category, startTime, ticketPrice, block.timestamp);
    }

    /**
     * @dev Update event information
     * @param eventId Event ID
     * @param title New title
     * @param description New description
     * @param venue New venue
     * @param location New location
     * @param startTime New start time
     * @param endTime New end time
     * @param ticketPrice New ticket price
     * @param maxTickets New max tickets
     */
    function updateEvent(
        string memory eventId,
        string memory title,
        string memory description,
        string memory venue,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        uint256 ticketPrice,
        uint256 maxTickets
    ) external eventExistsCheck(eventId) isEventProducer(eventId) {
        Event storage eventData = events[eventId];
        require(!eventData.isCancelled, "Event is cancelled");
        require(block.timestamp < eventData.startTime, "Event has already started");

        if (bytes(title).length > 0) eventData.title = title;
        if (bytes(description).length > 0) eventData.description = description;
        if (bytes(venue).length > 0) eventData.venue = venue;
        if (bytes(location).length > 0) eventData.location = location;
        if (startTime > 0 && startTime > block.timestamp) eventData.startTime = startTime;
        if (endTime > 0 && endTime > startTime) eventData.endTime = endTime;
        if (ticketPrice > 0) eventData.ticketPrice = ticketPrice;
        if (maxTickets > 0 && maxTickets >= eventData.ticketsSold) {
            eventData.maxTickets = maxTickets;
        }

        emit EventUpdated(eventId, eventData.title, eventData.startTime, block.timestamp);
    }

    /**
     * @dev Cancel an event
     * @param eventId Event ID
     */
    function cancelEvent(string memory eventId) external eventExistsCheck(eventId) isEventProducer(eventId) {
        Event storage eventData = events[eventId];
        require(!eventData.isCancelled, "Event already cancelled");
        require(block.timestamp < eventData.startTime, "Event has already started");

        eventData.isCancelled = true;
        eventData.isActive = false;

        emit EventCancelled(eventId, block.timestamp);
    }

    /**
     * @dev Activate/deactivate event
     * @param eventId Event ID
     * @param isActive Active status
     */
    function setEventActive(string memory eventId, bool isActive) external eventExistsCheck(eventId) isEventProducer(eventId) {
        Event storage eventData = events[eventId];
        require(!eventData.isCancelled, "Cannot activate cancelled event");

        eventData.isActive = isActive;

        emit EventActivated(eventId, isActive, block.timestamp);
    }

    /**
     * @dev Update tickets sold (called by Ticketing contract)
     * @param eventId Event ID
     * @param ticketsSold Number of tickets sold
     */
    function updateTicketsSold(
        string memory eventId,
        uint256 ticketsSold
    ) external {
        // Only allow calls from authorized contracts (Ticketing)
        require(
            msg.sender == owner() || 
            tx.origin == owner(),
            "Unauthorized"
        );

        Event storage eventData = events[eventId];
        require(eventData.ticketsSold + ticketsSold <= eventData.maxTickets, "Exceeds max tickets");
        eventData.ticketsSold += ticketsSold;
    }

    /**
     * @dev Get event information
     * @param eventId Event ID
     * @return eventData Event information
     * @return category Event category
     */
    function getEvent(string memory eventId) external view eventExistsCheck(eventId) returns (Event memory eventData, EventCategory category) {
        return (events[eventId], eventCategories[eventId]);
    }

    /**
     * @dev Get events by producer
     * @param producerId Producer ID
     * @return eventIds Array of event IDs
     */
    function getProducerEvents(string memory producerId) external view returns (string[] memory eventIds) {
        return producerEvents[producerId];
    }

    /**
     * @dev Check if event exists
     * @param eventId Event ID
     * @return exists Whether the event exists
     */
    function exists(string memory eventId) external view returns (bool exists) {
        return eventExists[eventId];
    }

    /**
     * @dev Get event category
     * @param eventId Event ID
     * @return category Event category
     */
    function getEventCategory(string memory eventId) external view eventExistsCheck(eventId) returns (EventCategory category) {
        return eventCategories[eventId];
    }

    /**
     * @dev Internal function to check if caller is producer owner
     */
    function _isProducerOwner(string memory producerId) internal view returns (bool) {
        try eventProducer.getProducer(producerId) returns (EventProducer.Producer memory producer) {
            return producer.walletAddress == msg.sender;
        } catch {
            return false;
        }
    }

    /**
     * @dev Emergency function to deactivate event (owner only)
     * @param eventId Event ID
     */
    function emergencyDeactivateEvent(string memory eventId) external onlyOwner eventExistsCheck(eventId) {
        events[eventId].isActive = false;
    }
}

