// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./GoldfireToken.sol";
import "./EventProducer.sol";
import "./EventListings.sol";

/**
 * @title HouseMembership
 * @dev Manages house membership and community features for Superstar Avatar system
 */
contract HouseMembership is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Goldfire token contract
    GoldfireToken public goldfireToken;
    
    // Event producer contract
    EventProducer public eventProducer;
    
    // Event listings contract
    EventListings public eventListings;
    
    // Minimum votes required for activity approval (default: 2)
    uint256 public minVotesRequired;
    
    // Goldfire token reward per experience point (1 GF per 100 XP by default)
    uint256 public goldfirePerExperience;

    function initialize(
        address _goldfireToken,
        address _eventProducer,
        address _eventListings
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        require(_goldfireToken != address(0), "Invalid GoldfireToken address");
        require(_eventProducer != address(0), "Invalid EventProducer address");
        require(_eventListings != address(0), "Invalid EventListings address");
        goldfireToken = GoldfireToken(_goldfireToken);
        eventProducer = EventProducer(_eventProducer);
        eventListings = EventListings(_eventListings);
        
        // Initialize default values
        minVotesRequired = 2;
        goldfirePerExperience = 100;
    }
    
    /**
     * @dev Set Goldfire token contract (owner only)
     */
    function setGoldfireToken(address _goldfireToken) external onlyOwner {
        require(_goldfireToken != address(0), "Invalid address");
        goldfireToken = GoldfireToken(_goldfireToken);
    }
    
    /**
     * @dev Set EventProducer contract (owner only)
     */
    function setEventProducer(address _eventProducer) external onlyOwner {
        require(_eventProducer != address(0), "Invalid address");
        eventProducer = EventProducer(_eventProducer);
    }
    
    /**
     * @dev Set EventListings contract (owner only)
     */
    function setEventListings(address _eventListings) external onlyOwner {
        require(_eventListings != address(0), "Invalid address");
        eventListings = EventListings(_eventListings);
    }
    
    /**
     * @dev Set minimum votes required (owner only)
     */
    function setMinVotesRequired(uint256 _minVotes) external onlyOwner {
        require(_minVotes > 0, "Minimum votes must be greater than 0");
        minVotesRequired = _minVotes;
    }
    
    /**
     * @dev Set Goldfire per experience rate (owner only)
     */
    function setGoldfirePerExperience(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate must be greater than 0");
        goldfirePerExperience = _rate;
    }

    /**
     * @dev Authorize upgrade (only owner)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // House structure
    struct House {
        string id;
        string name;
        string description;
        string eventId;
        string eventName;
        address leader;
        uint256 memberCount;
        uint256 maxMembers;
        uint256 totalExperience;
        uint256 averageLevel;
        uint256 createdAt;
        bool isActive;
        string metadata; // JSON string for additional data
    }

    // Member structure
    struct Member {
        string avatarId;
        string avatarName;
        address walletAddress;
        uint256 joinedAt;
        uint256 lastActive;
        uint256 contributionScore;
        bool isActive;
    }

    // House activity structure
    struct HouseActivity {
        string activityId;
        string title;
        string description;
        uint256 experienceReward;
        uint256 completedBy;
        uint256 createdAt;
        bool isActive;
        bool isApproved; // Whether activity has been approved
        address proposer; // Address that proposed the activity
    }
    
    // Pending activity proposal structure
    struct PendingActivity {
        string activityId;
        string title;
        string description;
        uint256 experienceReward;
        address proposer;
        uint256 createdAt;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isApproved;
        bool isRejected;
    }
    
    // Vote structure
    struct Vote {
        address voter;
        bool inFavor;
        uint256 timestamp;
    }

    // Counters (replaced Counters.Counter with uint256 in OpenZeppelin v5)
    uint256 private _houseIds;
    uint256 private _activityIds;

    // Mappings
    mapping(string => House) public houses;
    mapping(string => mapping(string => Member)) public houseMembers; // houseId => avatarId => Member
    mapping(string => string[]) public houseMemberList; // houseId => avatarId[]
    mapping(string => string) public avatarToHouse; // avatarId => houseId
    mapping(string => HouseActivity[]) public houseActivities; // houseId => activities[]
    mapping(string => mapping(string => bool)) public activityCompletions; // activityId => avatarId => completed
    
    // Voting mappings
    mapping(string => PendingActivity) public pendingActivities; // activityId => PendingActivity
    mapping(string => Vote[]) public activityVotes; // activityId => Vote[]
    mapping(string => mapping(address => bool)) public hasVoted; // activityId => voter => hasVoted
    mapping(string => string[]) public housePendingActivities; // houseId => pendingActivityIds[]

    // Events
    event HouseCreated(
        string indexed houseId,
        string name,
        string eventId,
        address indexed leader,
        uint256 timestamp
    );

    event MemberJoined(
        string indexed houseId,
        string indexed avatarId,
        address indexed walletAddress,
        uint256 timestamp
    );

    event MemberLeft(
        string indexed houseId,
        string indexed avatarId,
        uint256 timestamp
    );

    event HouseActivityCreated(
        string indexed houseId,
        string indexed activityId,
        string title,
        uint256 experienceReward,
        uint256 timestamp
    );

    event ActivityCompleted(
        string indexed houseId,
        string indexed activityId,
        string indexed avatarId,
        uint256 experienceReward,
        uint256 timestamp
    );

    event HouseUpdated(
        string indexed houseId,
        string name,
        string description,
        uint256 timestamp
    );
    
    event ActivityProposed(
        string indexed houseId,
        string indexed activityId,
        string title,
        address indexed proposer,
        uint256 timestamp
    );
    
    event ActivityVoted(
        string indexed activityId,
        address indexed voter,
        bool inFavor,
        uint256 timestamp
    );
    
    event ActivityApproved(
        string indexed houseId,
        string indexed activityId,
        uint256 timestamp
    );
    
    event ActivityRejected(
        string indexed houseId,
        string indexed activityId,
        uint256 timestamp
    );
    
    event GoldfireRewarded(
        string indexed activityId,
        string indexed avatarId,
        address indexed recipient,
        uint256 goldfireAmount,
        uint256 timestamp
    );

    // Modifiers
    modifier houseExists(string memory houseId) {
        require(bytes(houses[houseId].id).length > 0, "House does not exist");
        _;
    }

    modifier isHouseLeader(string memory houseId) {
        require(houses[houseId].leader == msg.sender, "Only house leader can perform this action");
        _;
    }

    modifier isHouseMember(string memory houseId, string memory avatarId) {
        require(houseMembers[houseId][avatarId].isActive, "Not a member of this house");
        _;
    }

    modifier validAvatarId(string memory avatarId) {
        require(bytes(avatarId).length > 0, "Avatar ID cannot be empty");
        _;
    }

    modifier isEventProducer() {
        require(
            bytes(eventProducer.addressToProducerId(msg.sender)).length > 0,
            "Only event producers can create houses"
        );
        // Verify producer is active
        string memory producerId = eventProducer.addressToProducerId(msg.sender);
        EventProducer.Producer memory producer = eventProducer.getProducer(producerId);
        require(producer.isActive, "Producer is not active");
        _;
    }

    /**
     * @dev Create a new house (only event producers can create houses)
     * @param name House name
     * @param description House description
     * @param eventId Associated event ID (must belong to the producer)
     * @param eventName Associated event name
     * @param maxMembers Maximum number of members
     * @param metadata Additional house metadata
     */
    function createHouse(
        string memory name,
        string memory description,
        string memory eventId,
        string memory eventName,
        uint256 maxMembers,
        string memory metadata
    ) external isEventProducer {
        require(bytes(name).length > 0, "House name cannot be empty");
        require(maxMembers > 0 && maxMembers <= 50, "Invalid max members");
        require(bytes(eventId).length > 0, "Event ID cannot be empty");
        
        // Verify event exists and belongs to the producer
        require(eventListings.exists(eventId), "Event does not exist");
        (EventListings.Event memory eventData, ) = eventListings.getEvent(eventId);
        
        // Get producer ID from caller's address
        string memory producerId = eventProducer.addressToProducerId(msg.sender);
        require(
            keccak256(bytes(eventData.producerId)) == keccak256(bytes(producerId)),
            "Event does not belong to this producer"
        );
        
        _houseIds++;
        string memory houseId = string(abi.encodePacked("house-", _houseIds));
        
        House memory newHouse = House({
            id: houseId,
            name: name,
            description: description,
            eventId: eventId,
            eventName: eventName,
            leader: msg.sender,
            memberCount: 0,
            maxMembers: maxMembers,
            totalExperience: 0,
            averageLevel: 0,
            createdAt: block.timestamp,
            isActive: true,
            metadata: metadata
        });
        
        houses[houseId] = newHouse;
        
        emit HouseCreated(houseId, name, eventId, msg.sender, block.timestamp);
    }

    /**
     * @dev Join a house
     * @param houseId House ID to join
     * @param avatarId Avatar ID joining the house
     * @param avatarName Avatar name
     */
    function joinHouse(
        string memory houseId,
        string memory avatarId,
        string memory avatarName
    ) external houseExists(houseId) validAvatarId(avatarId) nonReentrant {
        House storage house = houses[houseId];
        require(house.isActive, "House is not active");
        require(house.memberCount < house.maxMembers, "House is full");
        require(bytes(avatarToHouse[avatarId]).length == 0, "Avatar already in a house");
        
        // Create member record
        Member memory newMember = Member({
            avatarId: avatarId,
            avatarName: avatarName,
            walletAddress: msg.sender,
            joinedAt: block.timestamp,
            lastActive: block.timestamp,
            contributionScore: 0,
            isActive: true
        });
        
        houseMembers[houseId][avatarId] = newMember;
        houseMemberList[houseId].push(avatarId);
        avatarToHouse[avatarId] = houseId;
        house.memberCount++;
        
        emit MemberJoined(houseId, avatarId, msg.sender, block.timestamp);
    }

    /**
     * @dev Leave a house
     * @param houseId House ID to leave
     * @param avatarId Avatar ID leaving the house
     */
    function leaveHouse(
        string memory houseId,
        string memory avatarId
    ) external houseExists(houseId) isHouseMember(houseId, avatarId) {
        require(houseMembers[houseId][avatarId].walletAddress == msg.sender, "Not your avatar");
        
        // Remove member
        houseMembers[houseId][avatarId].isActive = false;
        houses[houseId].memberCount--;
        delete avatarToHouse[avatarId];
        
        // Remove from member list
        string[] storage memberList = houseMemberList[houseId];
        for (uint256 i = 0; i < memberList.length; i++) {
            if (keccak256(bytes(memberList[i])) == keccak256(bytes(avatarId))) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        
        emit MemberLeft(houseId, avatarId, block.timestamp);
    }

    /**
     * @dev Propose a new house activity (requires voting if multiple members)
     * @param houseId House ID
     * @param title Activity title
     * @param description Activity description
     * @param experienceReward Experience reward for completion
     */
    function proposeHouseActivity(
        string memory houseId,
        string memory title,
        string memory description,
        uint256 experienceReward
    ) external houseExists(houseId) {
        House storage house = houses[houseId];
        require(house.isActive, "House is not active");
        require(bytes(title).length > 0, "Activity title cannot be empty");
        require(experienceReward > 0 && experienceReward <= 500, "Invalid experience reward");
        
        // Check if caller is house leader or member
        bool isLeader = house.leader == msg.sender;
        bool isMember = false;
        string[] memory members = houseMemberList[houseId];
        for (uint256 i = 0; i < members.length; i++) {
            if (houseMembers[houseId][members[i]].walletAddress == msg.sender && 
                houseMembers[houseId][members[i]].isActive) {
                isMember = true;
                break;
            }
        }
        require(isLeader || isMember, "Not a house member");
        
        _activityIds++;
        string memory activityId = string(abi.encodePacked("activity-", _activityIds));
        
        // If only leader (no other members), auto-approve
        // Otherwise, create pending activity for voting
        if (house.memberCount <= 1) {
            // Only leader, auto-approve
        HouseActivity memory newActivity = HouseActivity({
            activityId: activityId,
            title: title,
            description: description,
            experienceReward: experienceReward,
            completedBy: 0,
            createdAt: block.timestamp,
                isActive: true,
                isApproved: true,
                proposer: msg.sender
            });
            
            houseActivities[houseId].push(newActivity);
            emit ActivityApproved(houseId, activityId, block.timestamp);
            emit HouseActivityCreated(houseId, activityId, title, experienceReward, block.timestamp);
        } else {
            // Multiple members, require voting
            PendingActivity memory pending = PendingActivity({
                activityId: activityId,
                title: title,
                description: description,
                experienceReward: experienceReward,
                proposer: msg.sender,
                createdAt: block.timestamp,
                votesFor: 0,
                votesAgainst: 0,
                isApproved: false,
                isRejected: false
            });
            
            pendingActivities[activityId] = pending;
            housePendingActivities[houseId].push(activityId);
            
            emit ActivityProposed(houseId, activityId, title, msg.sender, block.timestamp);
        }
    }
    
    /**
     * @dev Vote on a pending activity
     * @param houseId House ID
     * @param activityId Activity ID to vote on
     * @param inFavor True to vote for, false to vote against
     */
    function voteOnActivity(
        string memory houseId,
        string memory activityId,
        bool inFavor
    ) external houseExists(houseId) {
        PendingActivity storage pending = pendingActivities[activityId];
        require(bytes(pending.activityId).length > 0, "Activity not found");
        require(!pending.isApproved && !pending.isRejected, "Activity already decided");
        require(!hasVoted[activityId][msg.sender], "Already voted");
        
        // Verify caller is a house member
        bool isMember = false;
        string memory voterAvatarId = "";
        string[] memory members = houseMemberList[houseId];
        for (uint256 i = 0; i < members.length; i++) {
            if (houseMembers[houseId][members[i]].walletAddress == msg.sender && 
                houseMembers[houseId][members[i]].isActive) {
                isMember = true;
                voterAvatarId = members[i];
                break;
            }
        }
        require(isMember, "Not a house member");
        
        // Record vote
        Vote memory vote = Vote({
            voter: msg.sender,
            inFavor: inFavor,
            timestamp: block.timestamp
        });
        
        activityVotes[activityId].push(vote);
        hasVoted[activityId][msg.sender] = true;
        
        if (inFavor) {
            pending.votesFor++;
        } else {
            pending.votesAgainst++;
        }
        
        emit ActivityVoted(activityId, msg.sender, inFavor, block.timestamp);
        
        // Check if activity should be approved or rejected
        uint256 totalVotes = pending.votesFor + pending.votesAgainst;
        House storage house = houses[houseId];
        
        // If leader votes, their vote counts as 2 votes (or auto-approve if only leader)
        if (house.leader == msg.sender && inFavor) {
            pending.votesFor++; // Leader vote counts double
            totalVotes++;
        }
        
        // Approve if we have enough votes
        if (pending.votesFor >= minVotesRequired) {
            _approveActivity(houseId, activityId, pending);
        } else if (pending.votesAgainst > pending.votesFor && totalVotes >= minVotesRequired) {
            // Reject if more votes against and we have enough total votes
            pending.isRejected = true;
            emit ActivityRejected(houseId, activityId, block.timestamp);
        }
    }
    
    /**
     * @dev Approve a pending activity (internal)
     */
    function _approveActivity(
        string memory houseId,
        string memory activityId,
        PendingActivity memory pending
    ) internal {
        HouseActivity memory newActivity = HouseActivity({
            activityId: pending.activityId,
            title: pending.title,
            description: pending.description,
            experienceReward: pending.experienceReward,
            completedBy: 0,
            createdAt: pending.createdAt,
            isActive: true,
            isApproved: true,
            proposer: pending.proposer
        });
        
        houseActivities[houseId].push(newActivity);
        pendingActivities[activityId].isApproved = true;
        
        emit ActivityApproved(houseId, activityId, block.timestamp);
        emit HouseActivityCreated(houseId, activityId, pending.title, pending.experienceReward, block.timestamp);
    }
    
    /**
     * @dev Leader can directly approve activity (bypass voting)
     * @param houseId House ID
     * @param activityId Activity ID to approve
     */
    function leaderApproveActivity(
        string memory houseId,
        string memory activityId
    ) external houseExists(houseId) isHouseLeader(houseId) {
        PendingActivity storage pending = pendingActivities[activityId];
        require(bytes(pending.activityId).length > 0, "Activity not found");
        require(!pending.isApproved && !pending.isRejected, "Activity already decided");
        
        _approveActivity(houseId, activityId, pending);
    }

    /**
     * @dev Complete a house activity and mint Goldfire tokens
     * @param houseId House ID
     * @param activityId Activity ID
     * @param avatarId Avatar ID completing the activity
     */
    function completeActivity(
        string memory houseId,
        string memory activityId,
        string memory avatarId
    ) external houseExists(houseId) isHouseMember(houseId, avatarId) nonReentrant {
        require(!activityCompletions[activityId][avatarId], "Activity already completed");
        
        // Find the activity
        HouseActivity[] storage activities = houseActivities[houseId];
        bool activityFound = false;
        uint256 experienceReward = 0;
        
        for (uint256 i = 0; i < activities.length; i++) {
            if (keccak256(bytes(activities[i].activityId)) == keccak256(bytes(activityId))) {
                require(activities[i].isActive && activities[i].isApproved, "Activity is not active or approved");
                activityFound = true;
                experienceReward = activities[i].experienceReward;
                activities[i].completedBy++;
                break;
            }
        }
        
        require(activityFound, "Activity not found");
        
        // Mark as completed
        activityCompletions[activityId][avatarId] = true;
        
        // Get member wallet address for token reward
        Member memory member = houseMembers[houseId][avatarId];
        address recipient = member.walletAddress;
        
        // Update member contribution score
        houseMembers[houseId][avatarId].contributionScore += experienceReward;
        houseMembers[houseId][avatarId].lastActive = block.timestamp;
        
        // Update house stats
        houses[houseId].totalExperience += experienceReward;
        
        // Calculate and mint Goldfire tokens (1 GF per 100 XP by default)
        uint256 goldfireReward = (experienceReward * 1e18) / goldfirePerExperience;
        if (goldfireReward > 0 && address(goldfireToken) != address(0)) {
            try goldfireToken.mintByAuthorized(recipient, goldfireReward) {
                emit GoldfireRewarded(activityId, avatarId, recipient, goldfireReward, block.timestamp);
            } catch {
                // If minting fails, still complete the activity but log the failure
                // In production, you might want to handle this differently
            }
        }
        
        emit ActivityCompleted(houseId, activityId, avatarId, experienceReward, block.timestamp);
    }

    /**
     * @dev Get house information
     * @param houseId House ID
     * @return house House information
     */
    function getHouse(string memory houseId) external view houseExists(houseId) returns (House memory house) {
        return houses[houseId];
    }

    /**
     * @dev Get house members
     * @param houseId House ID
     * @return members Array of member avatar IDs
     */
    function getHouseMembers(string memory houseId) external view houseExists(houseId) returns (string[] memory members) {
        return houseMemberList[houseId];
    }

    /**
     * @dev Get member information
     * @param houseId House ID
     * @param avatarId Avatar ID
     * @return member Member information
     */
    function getMember(
        string memory houseId,
        string memory avatarId
    ) external view houseExists(houseId) returns (Member memory member) {
        return houseMembers[houseId][avatarId];
    }

    /**
     * @dev Get house activities
     * @param houseId House ID
     * @return activities Array of house activities
     */
    function getHouseActivities(string memory houseId) external view houseExists(houseId) returns (HouseActivity[] memory activities) {
        return houseActivities[houseId];
    }
    
    /**
     * @dev Get pending activities for a house
     * @param houseId House ID
     * @return pendingActivityIds Array of pending activity IDs
     */
    function getPendingActivities(string memory houseId) external view houseExists(houseId) returns (string[] memory pendingActivityIds) {
        return housePendingActivities[houseId];
    }
    
    /**
     * @dev Get pending activity details
     * @param activityId Activity ID
     * @return pending Pending activity details
     */
    function getPendingActivity(string memory activityId) external view returns (PendingActivity memory pending) {
        return pendingActivities[activityId];
    }
    
    /**
     * @dev Get votes for an activity
     * @param activityId Activity ID
     * @return votes Array of votes
     */
    function getActivityVotes(string memory activityId) external view returns (Vote[] memory votes) {
        return activityVotes[activityId];
    }
    
    /**
     * @dev Check if address has voted on activity
     * @param activityId Activity ID
     * @param voter Voter address
     * @return hasVotedOnActivity True if voter has voted
     */
    function checkHasVoted(string memory activityId, address voter) external view returns (bool hasVotedOnActivity) {
        return hasVoted[activityId][voter];
    }

    /**
     * @dev Get avatar's house
     * @param avatarId Avatar ID
     * @return houseId House ID the avatar belongs to
     */
    function getAvatarHouse(string memory avatarId) external view validAvatarId(avatarId) returns (string memory houseId) {
        return avatarToHouse[avatarId];
    }

    /**
     * @dev Update house information (leader only)
     * @param houseId House ID
     * @param name New house name
     * @param description New house description
     * @param metadata New house metadata
     */
    function updateHouse(
        string memory houseId,
        string memory name,
        string memory description,
        string memory metadata
    ) external houseExists(houseId) isHouseLeader(houseId) {
        House storage house = houses[houseId];
        if (bytes(name).length > 0) house.name = name;
        if (bytes(description).length > 0) house.description = description;
        if (bytes(metadata).length > 0) house.metadata = metadata;
        
        emit HouseUpdated(houseId, name, description, block.timestamp);
    }

    /**
     * @dev Transfer house leadership
     * @param houseId House ID
     * @param newLeader New leader address
     */
    function transferLeadership(
        string memory houseId,
        address newLeader
    ) external houseExists(houseId) isHouseLeader(houseId) {
        require(newLeader != address(0), "Invalid new leader address");
        houses[houseId].leader = newLeader;
    }

    /**
     * @dev Deactivate house (leader only)
     * @param houseId House ID
     */
    function deactivateHouse(string memory houseId) external houseExists(houseId) isHouseLeader(houseId) {
        houses[houseId].isActive = false;
    }

    /**
     * @dev Get houses by event
     * @param eventId Event ID
     * @return houseIds Array of house IDs for the event
     */
    function getHousesByEvent(string memory eventId) external view returns (string[] memory houseIds) {
        // This would require additional storage or events to track efficiently
        // For now, return empty array - implement with events or additional mapping
        return new string[](0);
    }

    /**
     * @dev Emergency function to remove member (owner only)
     * @param houseId House ID
     * @param avatarId Avatar ID to remove
     */
    function emergencyRemoveMember(
        string memory houseId,
        string memory avatarId
    ) external onlyOwner houseExists(houseId) {
        if (houseMembers[houseId][avatarId].isActive) {
            houseMembers[houseId][avatarId].isActive = false;
            houses[houseId].memberCount--;
            delete avatarToHouse[avatarId];
            
            emit MemberLeft(houseId, avatarId, block.timestamp);
        }
    }
} 