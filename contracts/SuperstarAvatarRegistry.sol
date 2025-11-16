// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SuperstarAvatarRegistry
 * @dev Manages the registry of Superstar Avatars and their achievements
 */
contract SuperstarAvatarRegistry is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Power types enum (kept for reference with other contracts)
    enum PowerType { Courage, Creativity, Connection, Insight, Kindness }

    // Superstar Avatar structure
    struct SuperstarAvatar {
        string id;
        string name;
        string bio;
        address walletAddress;
        uint256 totalExperience;
        uint256[5] powerLevels; // Levels for each power type
        uint256[5] powerExperience; // Experience for each power type
        uint256 achievedAt;
        uint256 lastActive;
        string[] achievements;
        string[] badges;
        bool isActive;
        string metadata; // JSON string for additional data
    }

    // Achievement structure
    struct Achievement {
        string id;
        string title;
        string description;
        string category;
        uint256 experienceReward;
        uint256 rarity; // 1-5 stars
        bool isActive;
        uint256 achievedCount;
    }

    // Badge structure
    struct Badge {
        string id;
        string name;
        string description;
        string imageUri;
        uint256 rarity; // 1-5 stars
        bool isActive;
        uint256 awardedCount;
    }

    // Counters
    Counters.Counter private _superstarIds;
    Counters.Counter private _achievementIds;
    Counters.Counter private _badgeIds;

    // Mappings
    mapping(string => SuperstarAvatar) public superstarAvatars;
    mapping(address => string) public addressToSuperstarId;
    mapping(string => Achievement) public achievements;
    mapping(string => Badge) public badges;
    mapping(string => mapping(string => bool)) public avatarAchievements; // avatarId => achievementId => achieved
    mapping(string => mapping(string => bool)) public avatarBadges; // avatarId => badgeId => awarded
    mapping(string => string[]) public avatarAchievementList; // avatarId => achievementId[]
    mapping(string => string[]) public avatarBadgeList; // avatarId => badgeId[]

    // Events
    event SuperstarAvatarRegistered(
        string indexed avatarId,
        string name,
        address indexed walletAddress,
        uint256 totalExperience,
        uint256 timestamp
    );

    event AchievementUnlocked(
        string indexed avatarId,
        string indexed achievementId,
        string title,
        uint256 experienceReward,
        uint256 timestamp
    );

    event BadgeAwarded(
        string indexed avatarId,
        string indexed badgeId,
        string name,
        uint256 timestamp
    );

    event AchievementCreated(
        string indexed achievementId,
        string title,
        string category,
        uint256 experienceReward,
        uint256 timestamp
    );

    event BadgeCreated(
        string indexed badgeId,
        string name,
        string imageUri,
        uint256 rarity,
        uint256 timestamp
    );

    event SuperstarAvatarUpdated(
        string indexed avatarId,
        string name,
        uint256 totalExperience,
        uint256 timestamp
    );

    // Modifiers
    modifier superstarExists(string memory avatarId) {
        require(bytes(superstarAvatars[avatarId].id).length > 0, "Superstar Avatar does not exist");
        _;
    }

    modifier isSuperstarOwner(string memory avatarId) {
        require(superstarAvatars[avatarId].walletAddress == msg.sender, "Not the Superstar Avatar owner");
        _;
    }

    modifier validAvatarId(string memory avatarId) {
        require(bytes(avatarId).length > 0, "Avatar ID cannot be empty");
        _;
    }

    modifier achievementExists(string memory achievementId) {
        require(bytes(achievements[achievementId].id).length > 0, "Achievement does not exist");
        _;
    }

    modifier badgeExists(string memory badgeId) {
        require(bytes(badges[badgeId].id).length > 0, "Badge does not exist");
        _;
    }

    /**
     * @dev Register a new Superstar Avatar
     * @param avatarId Avatar ID
     * @param name Avatar name
     * @param bio Avatar bio
     * @param powerLevels Array of power levels [Courage, Creativity, Connection, Insight, Kindness]
     * @param powerExperience Array of power experience
     * @param totalExperience Total experience across all powers
     */
    function registerSuperstarAvatar(
        string memory avatarId,
        string memory name,
        string memory bio,
        uint256[5] memory powerLevels,
        uint256[5] memory powerExperience,
        uint256 totalExperience
    ) external validAvatarId(avatarId) nonReentrant {
        require(bytes(superstarAvatars[avatarId].id).length == 0, "Superstar Avatar already registered");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(totalExperience >= 13500, "Insufficient total experience for Superstar Avatar");

        // Verify all powers are at max level
        for (uint256 i = 0; i < 5; i++) {
            require(powerLevels[i] == 10, "All powers must be at maximum level");
        }

        _superstarIds.increment();

        SuperstarAvatar memory newSuperstar = SuperstarAvatar({
            id: avatarId,
            name: name,
            bio: bio,
            walletAddress: msg.sender,
            totalExperience: totalExperience,
            powerLevels: powerLevels,
            powerExperience: powerExperience,
            achievedAt: block.timestamp,
            lastActive: block.timestamp,
            achievements: new string[](0),
            badges: new string[](0),
            isActive: true,
            metadata: ""
        });

        superstarAvatars[avatarId] = newSuperstar;
        addressToSuperstarId[msg.sender] = avatarId;

        emit SuperstarAvatarRegistered(avatarId, name, msg.sender, totalExperience, block.timestamp);
    }

    /**
     * @dev Update Superstar Avatar information
     * @param avatarId Avatar ID
     * @param name New name
     * @param bio New bio
     * @param metadata New metadata
     */
    function updateSuperstarAvatar(
        string memory avatarId,
        string memory name,
        string memory bio,
        string memory metadata
    ) external superstarExists(avatarId) isSuperstarOwner(avatarId) {
        SuperstarAvatar storage superstar = superstarAvatars[avatarId];
        if (bytes(name).length > 0) superstar.name = name;
        if (bytes(bio).length > 0) superstar.bio = bio;
        if (bytes(metadata).length > 0) superstar.metadata = metadata;
        superstar.lastActive = block.timestamp;

        emit SuperstarAvatarUpdated(avatarId, superstar.name, superstar.totalExperience, block.timestamp);
    }

    /**
     * @dev Unlock an achievement for a Superstar Avatar
     * @param avatarId Avatar ID
     * @param achievementId Achievement ID
     */
    function unlockAchievement(
        string memory avatarId,
        string memory achievementId
    ) external superstarExists(avatarId) achievementExists(achievementId) {
        require(!avatarAchievements[avatarId][achievementId], "Achievement already unlocked");

        Achievement storage achievement = achievements[achievementId];
        require(achievement.isActive, "Achievement is not active");

        // Add achievement to avatar
        avatarAchievements[avatarId][achievementId] = true;
        avatarAchievementList[avatarId].push(achievementId);
        achievement.achievedCount++;

        // Add experience reward
        SuperstarAvatar storage superstar = superstarAvatars[avatarId];
        superstar.totalExperience += achievement.experienceReward;
        superstar.lastActive = block.timestamp;

        emit AchievementUnlocked(avatarId, achievementId, achievement.title, achievement.experienceReward, block.timestamp);
    }

    /**
     * @dev Award a badge to a Superstar Avatar
     * @param avatarId Avatar ID
     * @param badgeId Badge ID
     */
    function awardBadge(
        string memory avatarId,
        string memory badgeId
    ) external superstarExists(avatarId) badgeExists(badgeId) {
        require(!avatarBadges[avatarId][badgeId], "Badge already awarded");

        Badge storage badge = badges[badgeId];
        require(badge.isActive, "Badge is not active");

        // Add badge to avatar
        avatarBadges[avatarId][badgeId] = true;
        avatarBadgeList[avatarId].push(badgeId);
        badge.awardedCount++;

        // Update avatar
        SuperstarAvatar storage superstar = superstarAvatars[avatarId];
        superstar.lastActive = block.timestamp;

        emit BadgeAwarded(avatarId, badgeId, badge.name, block.timestamp);
    }

    /**
     * @dev Create a new achievement (owner only)
     * @param title Achievement title
     * @param description Achievement description
     * @param category Achievement category
     * @param experienceReward Experience reward
     * @param rarity Rarity level (1-5 stars)
     */
    function createAchievement(
        string memory title,
        string memory description,
        string memory category,
        uint256 experienceReward,
        uint256 rarity
    ) external onlyOwner {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(experienceReward > 0 && experienceReward <= 1000, "Invalid experience reward");
        require(rarity >= 1 && rarity <= 5, "Invalid rarity");

        _achievementIds.increment();
        string memory achievementId = string(abi.encodePacked("achievement-", _achievementIds.current()));

        Achievement memory newAchievement = Achievement({
            id: achievementId,
            title: title,
            description: description,
            category: category,
            experienceReward: experienceReward,
            rarity: rarity,
            isActive: true,
            achievedCount: 0
        });

        achievements[achievementId] = newAchievement;

        emit AchievementCreated(achievementId, title, category, experienceReward, block.timestamp);
    }

    /**
     * @dev Create a new badge (owner only)
     * @param name Badge name
     * @param description Badge description
     * @param imageUri Badge image URI
     * @param rarity Rarity level (1-5 stars)
     */
    function createBadge(
        string memory name,
        string memory description,
        string memory imageUri,
        uint256 rarity
    ) external onlyOwner {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(rarity >= 1 && rarity <= 5, "Invalid rarity");

        _badgeIds.increment();
        string memory badgeId = string(abi.encodePacked("badge-", _badgeIds.current()));

        Badge memory newBadge = Badge({
            id: badgeId,
            name: name,
            description: description,
            imageUri: imageUri,
            rarity: rarity,
            isActive: true,
            awardedCount: 0
        });

        badges[badgeId] = newBadge;

        emit BadgeCreated(badgeId, name, imageUri, rarity, block.timestamp);
    }

    /**
     * @dev Get Superstar Avatar information
     * @param avatarId Avatar ID
     * @return superstar Superstar Avatar information
     */
    function getSuperstarAvatar(string memory avatarId) external view superstarExists(avatarId) returns (SuperstarAvatar memory superstar) {
        return superstarAvatars[avatarId];
    }

    /**
     * @dev Get Superstar Avatar by wallet address
     * @param walletAddress Wallet address
     * @return superstar Superstar Avatar information
     */
    function getSuperstarAvatarByAddress(address walletAddress) external view returns (SuperstarAvatar memory superstar) {
        string memory avatarId = addressToSuperstarId[walletAddress];
        require(bytes(avatarId).length > 0, "No Superstar Avatar found for address");
        return superstarAvatars[avatarId];
    }

    /**
     * @dev Get avatar achievements
     * @param avatarId Avatar ID
     * @return achievementIds Array of achievement IDs
     */
    function getAvatarAchievements(string memory avatarId) external view superstarExists(avatarId) returns (string[] memory achievementIds) {
        return avatarAchievementList[avatarId];
    }

    /**
     * @dev Get avatar badges
     * @param avatarId Avatar ID
     * @return badgeIds Array of badge IDs
     */
    function getAvatarBadges(string memory avatarId) external view superstarExists(avatarId) returns (string[] memory badgeIds) {
        return avatarBadgeList[avatarId];
    }

    /**
     * @dev Get achievement information
     * @param achievementId Achievement ID
     * @return achievement Achievement information
     */
    function getAchievement(string memory achievementId) external view returns (Achievement memory achievement) {
        return achievements[achievementId];
    }

    /**
     * @dev Get badge information
     * @param badgeId Badge ID
     * @return badge Badge information
     */
    function getBadge(string memory badgeId) external view returns (Badge memory badge) {
        return badges[badgeId];
    }

    /**
     * @dev Check if avatar has achievement
     * @param avatarId Avatar ID
     * @param achievementId Achievement ID
     * @return hasAchievement Whether the avatar has the achievement
     */
    function hasAchievement(
        string memory avatarId,
        string memory achievementId
    ) external view superstarExists(avatarId) returns (bool hasAchievement) {
        return avatarAchievements[avatarId][achievementId];
    }

    /**
     * @dev Check if avatar has badge
     * @param avatarId Avatar ID
     * @param badgeId Badge ID
     * @return hasBadge Whether the avatar has the badge
     */
    function hasBadge(
        string memory avatarId,
        string memory badgeId
    ) external view superstarExists(avatarId) returns (bool hasBadge) {
        return avatarBadges[avatarId][badgeId];
    }

    /**
     * @dev Get all Superstar Avatars (not implemented for on-chain enumeration)
     * @return avatarIds Empty array (enumeration should be handled off-chain via events)
     */
    function getAllSuperstarAvatars() external pure returns (string[] memory avatarIds) {
        return new string[](0);
    }

    /**
     * @dev Update achievement (owner only)
     * @param achievementId Achievement ID
     * @param title New title
     * @param description New description
     * @param isActive Whether the achievement is active
     */
    function updateAchievement(
        string memory achievementId,
        string memory title,
        string memory description,
        bool isActive
    ) external onlyOwner {
        Achievement storage achievement = achievements[achievementId];
        require(bytes(achievement.id).length > 0, "Achievement does not exist");
        if (bytes(title).length > 0) achievement.title = title;
        if (bytes(description).length > 0) achievement.description = description;
        achievement.isActive = isActive;
    }

    /**
     * @dev Update badge (owner only)
     * @param badgeId Badge ID
     * @param name New name
     * @param description New description
     * @param isActive Whether the badge is active
     */
    function updateBadge(
        string memory badgeId,
        string memory name,
        string memory description,
        bool isActive
    ) external onlyOwner {
        Badge storage badge = badges[badgeId];
        require(bytes(badge.id).length > 0, "Badge does not exist");
        if (bytes(name).length > 0) badge.name = name;
        if (bytes(description).length > 0) badge.description = description;
        badge.isActive = isActive;
    }

    /**
     * @dev Emergency function to deactivate Superstar Avatar (owner only)
     * @param avatarId Avatar ID
     */
    function emergencyDeactivateSuperstarAvatar(string memory avatarId) external onlyOwner superstarExists(avatarId) {
        superstarAvatars[avatarId].isActive = false;
    }
} 