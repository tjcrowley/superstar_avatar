// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title HouseMembership
 * @dev Manages house membership and community features for Superstar Avatar system
 */
contract HouseMembership is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

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
    }

    // Counters
    Counters.Counter private _houseIds;
    Counters.Counter private _activityIds;

    // Mappings
    mapping(string => House) public houses;
    mapping(string => mapping(string => Member)) public houseMembers; // houseId => avatarId => Member
    mapping(string => string[]) public houseMemberList; // houseId => avatarId[]
    mapping(string => string) public avatarToHouse; // avatarId => houseId
    mapping(string => HouseActivity[]) public houseActivities; // houseId => activities[]
    mapping(string => mapping(string => bool)) public activityCompletions; // activityId => avatarId => completed

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

    /**
     * @dev Create a new house
     * @param name House name
     * @param description House description
     * @param eventId Associated event ID
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
    ) external validAvatarId(eventId) {
        require(bytes(name).length > 0, "House name cannot be empty");
        require(maxMembers > 0 && maxMembers <= 50, "Invalid max members");
        
        _houseIds.increment();
        string memory houseId = string(abi.encodePacked("house-", _houseIds.current()));
        
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
     * @dev Create a house activity
     * @param houseId House ID
     * @param title Activity title
     * @param description Activity description
     * @param experienceReward Experience reward for completion
     */
    function createHouseActivity(
        string memory houseId,
        string memory title,
        string memory description,
        uint256 experienceReward
    ) external houseExists(houseId) isHouseLeader(houseId) {
        require(bytes(title).length > 0, "Activity title cannot be empty");
        require(experienceReward > 0 && experienceReward <= 500, "Invalid experience reward");
        
        _activityIds.increment();
        string memory activityId = string(abi.encodePacked("activity-", _activityIds.current()));
        
        HouseActivity memory newActivity = HouseActivity({
            activityId: activityId,
            title: title,
            description: description,
            experienceReward: experienceReward,
            completedBy: 0,
            createdAt: block.timestamp,
            isActive: true
        });
        
        houseActivities[houseId].push(newActivity);
        
        emit HouseActivityCreated(houseId, activityId, title, experienceReward, block.timestamp);
    }

    /**
     * @dev Complete a house activity
     * @param houseId House ID
     * @param activityId Activity ID
     * @param avatarId Avatar ID completing the activity
     */
    function completeActivity(
        string memory houseId,
        string memory activityId,
        string memory avatarId
    ) external houseExists(houseId) isHouseMember(houseId, avatarId) {
        require(!activityCompletions[activityId][avatarId], "Activity already completed");
        
        // Find the activity
        HouseActivity[] storage activities = houseActivities[houseId];
        bool activityFound = false;
        uint256 experienceReward = 0;
        
        for (uint256 i = 0; i < activities.length; i++) {
            if (keccak256(bytes(activities[i].activityId)) == keccak256(bytes(activityId))) {
                require(activities[i].isActive, "Activity is not active");
                activityFound = true;
                experienceReward = activities[i].experienceReward;
                activities[i].completedBy++;
                break;
            }
        }
        
        require(activityFound, "Activity not found");
        
        // Mark as completed
        activityCompletions[activityId][avatarId] = true;
        
        // Update member contribution score
        houseMembers[houseId][avatarId].contributionScore += experienceReward;
        houseMembers[houseId][avatarId].lastActive = block.timestamp;
        
        // Update house stats
        houses[houseId].totalExperience += experienceReward;
        
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