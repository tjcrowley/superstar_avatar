// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title EventProducer
 * @dev Manages event producer registration and verification
 */
contract EventProducer is Ownable, ReentrancyGuard {
    constructor() Ownable(msg.sender) {}

    // Event Producer structure
    struct Producer {
        string producerId;
        string avatarId;
        string name;
        string description;
        string stripeAccountId; // Stripe Connect account ID
        address walletAddress;
        uint256 createdAt;
        uint256 lastActive;
        uint256 totalEvents;
        uint256 totalTicketsSold;
        uint256 totalRevenue;
        bool isVerified;
        bool isActive;
        string metadata; // JSON string for additional data
    }

    // Counters
    // Counters (replaced Counters.Counter with uint256 in OpenZeppelin v5)
    uint256 private _producerIds;

    // Mappings
    mapping(string => Producer) public producers;
    mapping(address => string) public addressToProducerId;
    mapping(string => string) public avatarToProducerId; // avatarId => producerId
    mapping(string => bool) public verifiedProducers; // producerId => verified
    mapping(address => bool) public authorizedContracts; // authorized contract addresses

    // Events
    event ProducerRegistered(
        string indexed producerId,
        string indexed avatarId,
        string name,
        address indexed walletAddress,
        uint256 timestamp
    );

    event ProducerUpdated(
        string indexed producerId,
        string name,
        string description,
        uint256 timestamp
    );

    event ProducerVerified(
        string indexed producerId,
        bool verified,
        uint256 timestamp
    );

    event StripeAccountLinked(
        string indexed producerId,
        string stripeAccountId,
        uint256 timestamp
    );

    event ProducerDeactivated(
        string indexed producerId,
        uint256 timestamp
    );

    event ContractAuthorized(
        address indexed contractAddress,
        bool authorized,
        uint256 timestamp
    );

    // Modifiers
    modifier producerExists(string memory producerId) {
        require(bytes(producers[producerId].producerId).length > 0, "Producer does not exist");
        _;
    }

    modifier isProducerOwner(string memory producerId) {
        require(producers[producerId].walletAddress == msg.sender, "Not the producer owner");
        _;
    }

    modifier validProducerId(string memory producerId) {
        require(bytes(producerId).length > 0, "Producer ID cannot be empty");
        _;
    }

    /**
     * @dev Register as an event producer
     * @param producerId Producer ID
     * @param avatarId Avatar ID
     * @param name Producer name
     * @param description Producer description
     * @param metadata Additional metadata
     */
    function registerProducer(
        string memory producerId,
        string memory avatarId,
        string memory name,
        string memory description,
        string memory metadata
    ) external validProducerId(producerId) nonReentrant {
        require(bytes(producers[producerId].producerId).length == 0, "Producer already registered");
        require(bytes(avatarId).length > 0, "Avatar ID cannot be empty");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(avatarToProducerId[avatarId]).length == 0, "Avatar already registered as producer");

        _producerIds++;

        Producer memory newProducer = Producer({
            producerId: producerId,
            avatarId: avatarId,
            name: name,
            description: description,
            stripeAccountId: "",
            walletAddress: msg.sender,
            createdAt: block.timestamp,
            lastActive: block.timestamp,
            totalEvents: 0,
            totalTicketsSold: 0,
            totalRevenue: 0,
            isVerified: false,
            isActive: true,
            metadata: metadata
        });

        producers[producerId] = newProducer;
        addressToProducerId[msg.sender] = producerId;
        avatarToProducerId[avatarId] = producerId;

        emit ProducerRegistered(producerId, avatarId, name, msg.sender, block.timestamp);
    }

    /**
     * @dev Update producer information
     * @param producerId Producer ID
     * @param name New name
     * @param description New description
     * @param metadata New metadata
     */
    function updateProducer(
        string memory producerId,
        string memory name,
        string memory description,
        string memory metadata
    ) external producerExists(producerId) isProducerOwner(producerId) {
        Producer storage producer = producers[producerId];
        if (bytes(name).length > 0) producer.name = name;
        if (bytes(description).length > 0) producer.description = description;
        if (bytes(metadata).length > 0) producer.metadata = metadata;
        producer.lastActive = block.timestamp;

        emit ProducerUpdated(producerId, producer.name, producer.description, block.timestamp);
    }

    /**
     * @dev Link Stripe account to producer
     * @param producerId Producer ID
     * @param stripeAccountId Stripe Connect account ID
     */
    function linkStripeAccount(
        string memory producerId,
        string memory stripeAccountId
    ) external producerExists(producerId) isProducerOwner(producerId) {
        require(bytes(stripeAccountId).length > 0, "Stripe account ID cannot be empty");

        Producer storage producer = producers[producerId];
        producer.stripeAccountId = stripeAccountId;
        producer.lastActive = block.timestamp;

        emit StripeAccountLinked(producerId, stripeAccountId, block.timestamp);
    }

    /**
     * @dev Verify a producer (owner only)
     * @param producerId Producer ID
     * @param verified Verification status
     */
    function verifyProducer(
        string memory producerId,
        bool verified
    ) external onlyOwner producerExists(producerId) {
        Producer storage producer = producers[producerId];
        producer.isVerified = verified;
        verifiedProducers[producerId] = verified;

        emit ProducerVerified(producerId, verified, block.timestamp);
    }

    /**
     * @dev Update producer statistics (called by other contracts)
     * @param producerId Producer ID
     * @param eventsAdded Number of events added
     * @param ticketsSold Number of tickets sold
     * @param revenue Revenue generated
     */
    function updateProducerStats(
        string memory producerId,
        uint256 eventsAdded,
        uint256 ticketsSold,
        uint256 revenue
    ) external {
        // Only allow calls from owner or authorized contracts (EventListings, Ticketing)
        require(
            msg.sender == owner() || 
            authorizedContracts[msg.sender],
            "Unauthorized"
        );

        Producer storage producer = producers[producerId];
        producer.totalEvents += eventsAdded;
        producer.totalTicketsSold += ticketsSold;
        producer.totalRevenue += revenue;
        producer.lastActive = block.timestamp;
    }

    /**
     * @dev Authorize or revoke contract authorization (owner only)
     * @param contractAddress Address of the contract to authorize/revoke
     * @param authorized Whether to authorize the contract
     */
    function setAuthorizedContract(address contractAddress, bool authorized) external onlyOwner {
        require(contractAddress != address(0), "Invalid contract address");
        authorizedContracts[contractAddress] = authorized;
        emit ContractAuthorized(contractAddress, authorized, block.timestamp);
    }

    /**
     * @dev Get producer information
     * @param producerId Producer ID
     * @return producer Producer information
     */
    function getProducer(string memory producerId) external view producerExists(producerId) returns (Producer memory producer) {
        return producers[producerId];
    }

    /**
     * @dev Get producer by avatar ID
     * @param avatarId Avatar ID
     * @return producer Producer information
     */
    function getProducerByAvatar(string memory avatarId) external view returns (Producer memory producer) {
        string memory producerId = avatarToProducerId[avatarId];
        require(bytes(producerId).length > 0, "No producer found for avatar");
        return producers[producerId];
    }

    /**
     * @dev Get producer by wallet address
     * @param walletAddress Wallet address
     * @return producer Producer information
     */
    function getProducerByAddress(address walletAddress) external view returns (Producer memory producer) {
        string memory producerId = addressToProducerId[walletAddress];
        require(bytes(producerId).length > 0, "No producer found for address");
        return producers[producerId];
    }

    /**
     * @dev Check if avatar is a producer
     * @param avatarId Avatar ID
     * @return isProducer Whether the avatar is a producer
     */
    function isProducer(string memory avatarId) external view returns (bool isProducer) {
        return bytes(avatarToProducerId[avatarId]).length > 0;
    }

    /**
     * @dev Check if producer is verified
     * @param producerId Producer ID
     * @return verified Whether the producer is verified
     */
    function isVerified(string memory producerId) external view producerExists(producerId) returns (bool verified) {
        return producers[producerId].isVerified;
    }

    /**
     * @dev Deactivate producer (owner only)
     * @param producerId Producer ID
     */
    function deactivateProducer(string memory producerId) external onlyOwner producerExists(producerId) {
        producers[producerId].isActive = false;
        emit ProducerDeactivated(producerId, block.timestamp);
    }

    /**
     * @dev Emergency function to remove producer (owner only)
     * @param producerId Producer ID
     */
    function emergencyRemoveProducer(string memory producerId) external onlyOwner producerExists(producerId) {
        Producer storage producer = producers[producerId];
        delete addressToProducerId[producer.walletAddress];
        delete avatarToProducerId[producer.avatarId];
        delete producers[producerId];
    }
}

