// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./EventListings.sol";
import "./EventProducer.sol";

/**
 * @title Ticketing
 * @dev Manages ticket sales for events
 * Note: This contract handles on-chain ticket records. Actual payment processing happens off-chain via Stripe.
 */
contract Ticketing is Ownable, ReentrancyGuard {

    // Ticket structure
    struct Ticket {
        string ticketId;
        string eventId;
        string avatarId;
        address buyerAddress;
        uint256 purchaseTime;
        uint256 price;
        bool isValid;
        bool isUsed;
        string stripePaymentIntentId; // Stripe payment intent ID
        bytes32 qrCodeHash; // Hash of QR code data for verification
        uint256 checkedInAt; // Timestamp when ticket was checked in
        address checkedInBy; // Address that checked in the ticket
        string metadata; // JSON string for additional data
    }

    // Ticket tier structure
    struct TicketTier {
        string tierId;
        string name;
        uint256 price;
        uint256 maxTickets;
        uint256 ticketsSold;
        bool isActive;
    }

    // Platform fee structure
    struct PlatformFee {
        uint256 feePercentage; // Fee percentage (e.g., 500 = 5%)
        address feeRecipient; // Address to receive platform fees
    }

    // Counters
    // Counters (replaced Counters.Counter with uint256 in OpenZeppelin v5)
    uint256 private _ticketIds;

    // Contract references
    EventListings public eventListings;
    EventProducer public eventProducer;

    // Platform configuration
    PlatformFee public platformFee;

    // Mappings
    mapping(string => Ticket) public tickets;
    mapping(string => string[]) public eventTickets; // eventId => ticketId[]
    mapping(string => string[]) public avatarTickets; // avatarId => ticketId[]
    mapping(string => TicketTier[]) public eventTicketTiers; // eventId => tiers[]
    mapping(string => bool) public ticketExists; // ticketId => exists
    mapping(bytes32 => string) public qrCodeHashToTicketId; // QR code hash => ticketId
    mapping(string => bool) public qrCodeUsed; // ticketId => QR code used for check-in

    // Events
    event TicketPurchased(
        string indexed ticketId,
        string indexed eventId,
        string indexed avatarId,
        address buyerAddress,
        uint256 price,
        string stripePaymentIntentId,
        uint256 timestamp
    );

    event TicketValidated(
        string indexed ticketId,
        string indexed eventId,
        bool isValid,
        uint256 timestamp
    );

    event TicketUsed(
        string indexed ticketId,
        string indexed eventId,
        address indexed checkedInBy,
        uint256 timestamp
    );

    event TicketCheckedIn(
        string indexed ticketId,
        string indexed eventId,
        string indexed avatarId,
        address checkedInBy,
        uint256 timestamp
    );

    event TicketTierCreated(
        string indexed eventId,
        string tierId,
        string name,
        uint256 price,
        uint256 maxTickets,
        uint256 timestamp
    );

    event PlatformFeeUpdated(
        uint256 feePercentage,
        address feeRecipient,
        uint256 timestamp
    );

    // Modifiers
    modifier ticketExistsCheck(string memory ticketId) {
        require(ticketExists[ticketId], "Ticket does not exist");
        _;
    }

    modifier validTicketId(string memory ticketId) {
        require(bytes(ticketId).length > 0, "Ticket ID cannot be empty");
        _;
    }

    /**
     * @dev Constructor
     * @param _eventListings Address of EventListings contract
     * @param _eventProducer Address of EventProducer contract
     * @param _feePercentage Initial platform fee percentage (e.g., 500 = 5%)
     * @param _feeRecipient Address to receive platform fees
     */
    constructor(
        address _eventListings,
        address _eventProducer,
        uint256 _feePercentage,
        address _feeRecipient
    ) Ownable(msg.sender) {
        require(_eventListings != address(0), "Invalid EventListings address");
        require(_eventProducer != address(0), "Invalid EventProducer address");
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%"); // 10000 = 100%
        
        eventListings = EventListings(_eventListings);
        eventProducer = EventProducer(_eventProducer);
        platformFee = PlatformFee({
            feePercentage: _feePercentage,
            feeRecipient: _feeRecipient
        });
    }

    /**
     * @dev Create ticket after Stripe payment is confirmed
     * @param ticketId Ticket ID
     * @param eventId Event ID
     * @param avatarId Avatar ID of buyer
     * @param buyerAddress Wallet address of buyer
     * @param price Ticket price
     * @param stripePaymentIntentId Stripe payment intent ID
     * @param metadata Additional metadata
     */
    function createTicket(
        string memory ticketId,
        string memory eventId,
        string memory avatarId,
        address buyerAddress,
        uint256 price,
        string memory stripePaymentIntentId,
        string memory metadata
    ) external validTicketId(ticketId) nonReentrant {
        require(!ticketExists[ticketId], "Ticket already exists");
        require(bytes(eventId).length > 0, "Event ID cannot be empty");
        require(bytes(avatarId).length > 0, "Avatar ID cannot be empty");
        require(buyerAddress != address(0), "Invalid buyer address");
        require(price > 0, "Price must be greater than 0");

        // Verify event exists and is active
        (EventListings.Event memory eventData, ) = eventListings.getEvent(eventId);
        require(eventData.isActive && !eventData.isCancelled, "Event is not available");
        require(block.timestamp < eventData.startTime, "Event has already started");
        require(eventData.ticketsSold < eventData.maxTickets, "Event is sold out");

        _ticketIds++;

        // Generate QR code hash from ticket data
        bytes32 qrCodeHash = keccak256(abi.encodePacked(ticketId, eventId, avatarId, buyerAddress, block.timestamp));

        Ticket memory newTicket = Ticket({
            ticketId: ticketId,
            eventId: eventId,
            avatarId: avatarId,
            buyerAddress: buyerAddress,
            purchaseTime: block.timestamp,
            price: price,
            isValid: true,
            isUsed: false,
            stripePaymentIntentId: stripePaymentIntentId,
            qrCodeHash: qrCodeHash,
            checkedInAt: 0,
            checkedInBy: address(0),
            metadata: metadata
        });

        tickets[ticketId] = newTicket;
        ticketExists[ticketId] = true;
        qrCodeHashToTicketId[qrCodeHash] = ticketId;
        eventTickets[eventId].push(ticketId);
        avatarTickets[avatarId].push(ticketId);

        // Update event tickets sold
        eventListings.updateTicketsSold(eventId, 1);

        // Update producer stats
        eventProducer.updateProducerStats(eventData.producerId, 0, 1, price);

        emit TicketPurchased(
            ticketId,
            eventId,
            avatarId,
            buyerAddress,
            price,
            stripePaymentIntentId,
            block.timestamp
        );
    }

    /**
     * @dev Check in a ticket using QR code hash (for entry to event)
     * @param qrCodeHash Hash of the QR code data
     */
    function checkInTicket(bytes32 qrCodeHash) external nonReentrant {
        string memory ticketId = qrCodeHashToTicketId[qrCodeHash];
        require(bytes(ticketId).length > 0, "Invalid QR code");
        require(!qrCodeUsed[ticketId], "QR code already used");

        Ticket storage ticket = tickets[ticketId];
        require(ticket.isValid, "Ticket is not valid");
        require(!ticket.isUsed, "Ticket has already been used");

        // Verify event exists and get event data
        (EventListings.Event memory eventData, ) = eventListings.getEvent(ticket.eventId);
        
        // Check if event has started (allow check-in within reasonable time window)
        require(
            block.timestamp >= eventData.startTime - 1 hours &&
            block.timestamp <= eventData.endTime + 1 hours,
            "Outside check-in window"
        );

        // Verify caller is authorized (event producer or platform owner)
        EventProducer.Producer memory producer = eventProducer.getProducer(eventData.producerId);
        require(
            msg.sender == producer.walletAddress ||
            msg.sender == owner(),
            "Unauthorized check-in"
        );

        // Mark ticket as used and record check-in details
        ticket.isUsed = true;
        ticket.checkedInAt = block.timestamp;
        ticket.checkedInBy = msg.sender;
        qrCodeUsed[ticketId] = true;

        emit TicketCheckedIn(ticketId, ticket.eventId, ticket.avatarId, msg.sender, block.timestamp);
        emit TicketUsed(ticketId, ticket.eventId, msg.sender, block.timestamp);
    }

    /**
     * @dev Validate a ticket by ticket ID (alternative method)
     * @param ticketId Ticket ID
     */
    function validateTicket(string memory ticketId) external ticketExistsCheck(ticketId) {
        Ticket storage ticket = tickets[ticketId];
        require(ticket.isValid, "Ticket is not valid");
        require(!ticket.isUsed, "Ticket has already been used");

        // Verify event exists and get event data
        (EventListings.Event memory eventData, ) = eventListings.getEvent(ticket.eventId);
        
        // Check if event has started (allow validation within reasonable time window)
        require(
            block.timestamp >= eventData.startTime - 1 hours &&
            block.timestamp <= eventData.endTime + 1 hours,
            "Outside validation window"
        );

        // Verify caller is authorized (event producer or platform owner)
        EventProducer.Producer memory producer = eventProducer.getProducer(eventData.producerId);
        require(
            msg.sender == producer.walletAddress ||
            msg.sender == owner(),
            "Unauthorized validator"
        );

        ticket.isUsed = true;
        ticket.checkedInAt = block.timestamp;
        ticket.checkedInBy = msg.sender;

        emit TicketCheckedIn(ticketId, ticket.eventId, ticket.avatarId, msg.sender, block.timestamp);
        emit TicketUsed(ticketId, ticket.eventId, msg.sender, block.timestamp);
    }

    /**
     * @dev Get ticket ID from QR code hash
     * @param qrCodeHash Hash of the QR code
     * @return ticketId Ticket ID
     */
    function getTicketIdFromQrCode(bytes32 qrCodeHash) external view returns (string memory ticketId) {
        ticketId = qrCodeHashToTicketId[qrCodeHash];
        require(bytes(ticketId).length > 0, "Invalid QR code");
        return ticketId;
    }

    /**
     * @dev Invalidate a ticket (for refunds, etc.)
     * @param ticketId Ticket ID
     */
    function invalidateTicket(string memory ticketId) external ticketExistsCheck(ticketId) onlyOwner {
        Ticket storage ticket = tickets[ticketId];
        require(ticket.isValid, "Ticket already invalid");
        require(!ticket.isUsed, "Cannot invalidate used ticket");

        ticket.isValid = false;

        // Update event tickets sold
        eventListings.updateTicketsSold(ticket.eventId, 0); // Decrement handled off-chain

        emit TicketValidated(ticketId, ticket.eventId, false, block.timestamp);
    }

    /**
     * @dev Create ticket tier for an event
     * @param eventId Event ID
     * @param tierId Tier ID
     * @param name Tier name
     * @param price Tier price
     * @param maxTickets Maximum tickets for this tier
     */
    function createTicketTier(
        string memory eventId,
        string memory tierId,
        string memory name,
        uint256 price,
        uint256 maxTickets
    ) external {
        require(bytes(eventId).length > 0, "Event ID cannot be empty");
        require(bytes(tierId).length > 0, "Tier ID cannot be empty");
        require(bytes(name).length > 0, "Tier name cannot be empty");
        require(price > 0, "Price must be greater than 0");
        require(maxTickets > 0, "Max tickets must be greater than 0");

        // Verify caller is event producer
        (EventListings.Event memory eventData, ) = eventListings.getEvent(eventId);
        EventProducer.Producer memory producer = eventProducer.getProducer(eventData.producerId);
        require(producer.walletAddress == msg.sender, "Not the event producer");

        TicketTier memory newTier = TicketTier({
            tierId: tierId,
            name: name,
            price: price,
            maxTickets: maxTickets,
            ticketsSold: 0,
            isActive: true
        });

        eventTicketTiers[eventId].push(newTier);

        emit TicketTierCreated(eventId, tierId, name, price, maxTickets, block.timestamp);
    }

    /**
     * @dev Get ticket information
     * @param ticketId Ticket ID
     * @return ticket Ticket information
     */
    function getTicket(string memory ticketId) external view ticketExistsCheck(ticketId) returns (Ticket memory ticket) {
        return tickets[ticketId];
    }

    /**
     * @dev Get tickets for an event
     * @param eventId Event ID
     * @return ticketIds Array of ticket IDs
     */
    function getEventTickets(string memory eventId) external view returns (string[] memory ticketIds) {
        return eventTickets[eventId];
    }

    /**
     * @dev Get tickets for an avatar
     * @param avatarId Avatar ID
     * @return ticketIds Array of ticket IDs
     */
    function getAvatarTickets(string memory avatarId) external view returns (string[] memory ticketIds) {
        return avatarTickets[avatarId];
    }

    /**
     * @dev Get ticket tiers for an event
     * @param eventId Event ID
     * @return tiers Array of ticket tiers
     */
    function getEventTicketTiers(string memory eventId) external view returns (TicketTier[] memory tiers) {
        return eventTicketTiers[eventId];
    }

    /**
     * @dev Calculate platform fee
     * @param amount Ticket price
     * @return feeAmount Fee amount
     * @return netAmount Amount after fee
     */
    function calculateFee(uint256 amount) external view returns (uint256 feeAmount, uint256 netAmount) {
        feeAmount = (amount * platformFee.feePercentage) / 10000;
        netAmount = amount - feeAmount;
        return (feeAmount, netAmount);
    }

    /**
     * @dev Update platform fee (owner only)
     * @param feePercentage New fee percentage (e.g., 500 = 5%)
     * @param feeRecipient New fee recipient address
     */
    function updatePlatformFee(
        uint256 feePercentage,
        address feeRecipient
    ) external onlyOwner {
        require(feePercentage <= 2000, "Fee cannot exceed 20%");
        require(feeRecipient != address(0), "Invalid fee recipient");

        platformFee.feePercentage = feePercentage;
        platformFee.feeRecipient = feeRecipient;

        emit PlatformFeeUpdated(feePercentage, feeRecipient, block.timestamp);
    }

    /**
     * @dev Check if ticket exists
     * @param ticketId Ticket ID
     * @return exists Whether the ticket exists
     */
    function exists(string memory ticketId) external view returns (bool exists) {
        return ticketExists[ticketId];
    }
}

