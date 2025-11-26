// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title PowerVerification
 * @dev Manages power progression and verification for Superstar Avatar system
 */
contract PowerVerification is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Authorize upgrade (only owner)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Power types enum
    enum PowerType { Courage, Creativity, Connection, Insight, Kindness }

    // Power level requirements (experience needed for each level)
    uint256[] public levelRequirements = [
        0,    // Level 1
        100,  // Level 2
        250,  // Level 3
        450,  // Level 4
        700,  // Level 5
        1000, // Level 6
        1350, // Level 7
        1750, // Level 8
        2200, // Level 9
        2700  // Level 10
    ];

    // Avatar power data structure
    struct AvatarPower {
        uint256 level;
        uint256 experience;
        uint256 lastUpdated;
        bool isSuperstarAvatar;
    }

    // Verification record structure
    struct VerificationRecord {
        address verifier;
        uint256 timestamp;
        uint256 experience;
        string metadata;
    }

    // Mapping: avatarId => powerType => AvatarPower
    mapping(string => mapping(PowerType => AvatarPower)) public avatarPowers;
    
    // Mapping: avatarId => powerType => verification records
    mapping(string => mapping(PowerType => VerificationRecord[])) public verificationHistory;
    
    // Mapping: avatarId => total experience across all powers
    mapping(string => uint256) public totalExperience;
    
    // Mapping: verifier address => verification count
    mapping(address => uint256) public verifierCount;
    
    // Events
    event PowerVerified(
        string indexed avatarId,
        PowerType indexed powerType,
        uint256 experience,
        address indexed verifier,
        uint256 newLevel,
        uint256 timestamp
    );
    
    event SuperstarAvatarAchieved(
        string indexed avatarId,
        uint256 timestamp
    );
    
    event LevelUp(
        string indexed avatarId,
        PowerType indexed powerType,
        uint256 oldLevel,
        uint256 newLevel,
        uint256 timestamp
    );

    // Modifiers
    modifier validPowerType(PowerType powerType) {
        require(powerType <= PowerType.Kindness, "Invalid power type");
        _;
    }

    modifier validAvatarId(string memory avatarId) {
        require(bytes(avatarId).length > 0, "Avatar ID cannot be empty");
        _;
    }

    /**
     * @dev Verify a power for an avatar
     * @param avatarId The avatar's unique identifier
     * @param powerType The type of power being verified
     * @param experience The experience points to award
     * @param metadata Additional verification metadata
     */
    function verifyPower(
        string memory avatarId,
        PowerType powerType,
        uint256 experience,
        string memory metadata
    ) external validPowerType(powerType) validAvatarId(avatarId) nonReentrant {
        require(experience > 0, "Experience must be greater than 0");
        require(experience <= 1000, "Experience cannot exceed 1000 per verification");
        
        // Get current power data
        AvatarPower storage power = avatarPowers[avatarId][powerType];
        uint256 oldLevel = power.level;
        
        // Add experience
        power.experience += experience;
        power.lastUpdated = block.timestamp;
        
        // Check for level up
        uint256 newLevel = calculateLevel(power.experience);
        if (newLevel > oldLevel) {
            power.level = newLevel;
            emit LevelUp(avatarId, powerType, oldLevel, newLevel, block.timestamp);
        }
        
        // Update total experience
        totalExperience[avatarId] += experience;
        
        // Record verification
        VerificationRecord memory record = VerificationRecord({
            verifier: msg.sender,
            timestamp: block.timestamp,
            experience: experience,
            metadata: metadata
        });
        
        verificationHistory[avatarId][powerType].push(record);
        verifierCount[msg.sender]++;
        
        emit PowerVerified(
            avatarId,
            powerType,
            experience,
            msg.sender,
            newLevel,
            block.timestamp
        );
        
        // Check if avatar can become Superstar Avatar
        checkSuperstarAvatarStatus(avatarId);
    }

    /**
     * @dev Get power data for an avatar
     * @param avatarId The avatar's unique identifier
     * @param powerType The type of power
     * @return level Current level
     * @return experience Current experience
     * @return lastUpdated Last update timestamp
     * @return isSuperstarAvatar Superstar status
     */
    function getPowerData(
        string memory avatarId,
        PowerType powerType
    ) external view validPowerType(powerType) validAvatarId(avatarId) 
        returns (uint256 level, uint256 experience, uint256 lastUpdated, bool isSuperstarAvatar) {
        AvatarPower memory power = avatarPowers[avatarId][powerType];
        return (power.level, power.experience, power.lastUpdated, power.isSuperstarAvatar);
    }

    /**
     * @dev Get all power data for an avatar
     * @param avatarId The avatar's unique identifier
     * @return levels Array of levels for all powers
     * @return experiences Array of experience for all powers
     * @return totalExp Total experience across all powers
     */
    function getAllPowerData(
        string memory avatarId
    ) external view validAvatarId(avatarId) 
        returns (uint256[5] memory levels, uint256[5] memory experiences, uint256 totalExp) {
        
        for (uint256 i = 0; i < 5; i++) {
            AvatarPower memory power = avatarPowers[avatarId][PowerType(i)];
            levels[i] = power.level;
            experiences[i] = power.experience;
        }
        
        totalExp = totalExperience[avatarId];
        return (levels, experiences, totalExp);
    }

    /**
     * @dev Get verification history for a power
     * @param avatarId The avatar's unique identifier
     * @param powerType The type of power
     * @return records Array of verification records
     */
    function getVerificationHistory(
        string memory avatarId,
        PowerType powerType
    ) external view validPowerType(powerType) validAvatarId(avatarId) 
        returns (VerificationRecord[] memory records) {
        return verificationHistory[avatarId][powerType];
    }

    /**
     * @dev Check if avatar can become Superstar Avatar
     * @param avatarId The avatar's unique identifier
     * @return canBecomeSuperstar True if all powers are max level
     */
    function canBecomeSuperstarAvatar(
        string memory avatarId
    ) external view validAvatarId(avatarId) returns (bool) {
        for (uint256 i = 0; i < 5; i++) {
            if (avatarPowers[avatarId][PowerType(i)].level < 10) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Calculate level based on experience
     * @param experience Total experience points
     * @return level Calculated level
     */
    function calculateLevel(uint256 experience) public view returns (uint256) {
        for (uint256 i = levelRequirements.length - 1; i >= 0; i--) {
            if (experience >= levelRequirements[i]) {
                return i + 1;
            }
        }
        return 1;
    }

    /**
     * @dev Get experience required for next level
     * @param currentLevel Current level
     * @return experienceRequired Experience needed for next level
     */
    function getExperienceForNextLevel(uint256 currentLevel) external view returns (uint256) {
        require(currentLevel >= 1 && currentLevel <= 10, "Invalid level");
        if (currentLevel == 10) return 0;
        return levelRequirements[currentLevel];
    }

    /**
     * @dev Check and update Superstar Avatar status
     * @param avatarId The avatar's unique identifier
     */
    function checkSuperstarAvatarStatus(string memory avatarId) internal {
        bool allMaxLevel = true;
        for (uint256 i = 0; i < 5; i++) {
            if (avatarPowers[avatarId][PowerType(i)].level < 10) {
                allMaxLevel = false;
                break;
            }
        }
        
        if (allMaxLevel) {
            // Mark all powers as Superstar Avatar
            for (uint256 i = 0; i < 5; i++) {
                avatarPowers[avatarId][PowerType(i)].isSuperstarAvatar = true;
            }
            emit SuperstarAvatarAchieved(avatarId, block.timestamp);
        }
    }

    /**
     * @dev Get verifier statistics
     * @param verifier The verifier's address
     * @return verificationCount Number of verifications performed
     */
    function getVerifierStats(address verifier) external view returns (uint256 verificationCount) {
        return verifierCount[verifier];
    }

    /**
     * @dev Update level requirements (owner only)
     * @param newRequirements New level requirements array
     */
    function updateLevelRequirements(uint256[] memory newRequirements) external onlyOwner {
        require(newRequirements.length == 10, "Must have exactly 10 level requirements");
        levelRequirements = newRequirements;
    }

    /**
     * @dev Emergency function to reset avatar data (owner only)
     * @param avatarId The avatar's unique identifier
     */
    function emergencyResetAvatar(string memory avatarId) external onlyOwner validAvatarId(avatarId) {
        for (uint256 i = 0; i < 5; i++) {
            delete avatarPowers[avatarId][PowerType(i)];
            delete verificationHistory[avatarId][PowerType(i)];
        }
        delete totalExperience[avatarId];
    }
} 