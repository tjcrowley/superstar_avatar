// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title ActivityScripts
 * @dev Manages activity scripts and their verification for Superstar Avatar system
 */
contract ActivityScripts is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Power types enum
    enum PowerType { Courage, Creativity, Connection, Insight, Kindness }

    // Goldfire Activity Types enum (Phase 1 - Basic Activities)
    enum ActivityType {
        PersonalResources,  // Personal Resources
        Introductions,       // Introductions
        Dynamics,           // Dynamics
        Locales,            // Locales
        MythicLens,         // Mythic Lens
        Alchemy,            // Alchemy
        Tales               // Tales
    }

    // Activity script structure
    struct ActivityScript {
        string id;
        string title;
        string description;
        string instructions;
        ActivityType activityType;  // Required: One Activity Type
        PowerType primaryPower;
        PowerType[] secondaryPowers;  // Optional: up to 4 secondary powers
        uint256 experienceReward;
        uint256 difficulty;
        uint256 timeLimit; // in seconds, 0 for no limit
        uint256 maxCompletions;
        uint256 completedCount;
        uint256 createdAt;
        bool isActive;
        bool requiresVerification;
        string metadata; // JSON string for additional data (decentralized storage reference, Tales, etc.)
        string authorId; // Avatar ID or House ID of the author
        string decentralizedStorageRef; // IPFS hash or other decentralized storage reference
    }

    // Completion record structure
    struct CompletionRecord {
        string avatarId;
        address walletAddress;
        uint256 completedAt;
        uint256 experienceEarned;
        string proof; // IPFS hash or other proof
        bool verified;
        address verifier;
        uint256 verifiedAt;
    }

    // Verification request structure
    struct VerificationRequest {
        string avatarId;
        string activityId;
        uint256 requestedAt;
        bool isPending;
        string proof;
    }

    // Counters
    Counters.Counter private _scriptIds;
    Counters.Counter private _verificationIds;

    // Mappings
    mapping(string => ActivityScript) public activityScripts;
    mapping(string => mapping(string => CompletionRecord)) public completions; // activityId => avatarId => CompletionRecord
    mapping(string => string[]) public activityCompletions; // activityId => avatarId[]
    mapping(string => mapping(string => bool)) public hasCompleted; // activityId => avatarId => completed
    mapping(string => VerificationRequest[]) public verificationRequests; // activityId => requests[]
    mapping(address => bool) public authorizedVerifiers;
    mapping(string => mapping(string => uint256)) public completionTimestamps; // activityId => avatarId => timestamp

    // Events
    event ActivityScriptCreated(
        string indexed activityId,
        string title,
        ActivityType indexed activityType,
        PowerType indexed primaryPower,
        uint256 experienceReward,
        string authorId,
        uint256 timestamp
    );

    event ActivityCompleted(
        string indexed activityId,
        string indexed avatarId,
        address indexed walletAddress,
        uint256 experienceEarned,
        uint256 timestamp
    );

    event VerificationRequested(
        string indexed activityId,
        string indexed avatarId,
        string proof,
        uint256 timestamp
    );

    event ActivityVerified(
        string indexed activityId,
        string indexed avatarId,
        address indexed verifier,
        uint256 experienceEarned,
        uint256 timestamp
    );

    event VerifierAuthorized(
        address indexed verifier,
        bool authorized,
        uint256 timestamp
    );

    event ActivityScriptUpdated(
        string indexed activityId,
        string title,
        bool isActive,
        uint256 timestamp
    );

    /**
     * @dev Get activities by activity type
     * @param activityType Activity type to filter by
     * @return activityIds Array of activity IDs (requires event indexing for full implementation)
     */
    function getActivitiesByType(ActivityType activityType) external view returns (string[] memory activityIds) {
        // This would require additional storage or events to track efficiently
        // For now, return empty array - implement with events or additional mapping
        return new string[](0);
    }

    // Modifiers
    modifier scriptExists(string memory activityId) {
        require(bytes(activityScripts[activityId].id).length > 0, "Activity script does not exist");
        _;
    }

    modifier scriptActive(string memory activityId) {
        require(activityScripts[activityId].isActive, "Activity script is not active");
        _;
    }

    modifier notCompleted(string memory activityId, string memory avatarId) {
        require(!hasCompleted[activityId][avatarId], "Activity already completed");
        _;
    }

    modifier isAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender] || msg.sender == owner(), "Not authorized verifier");
        _;
    }

    modifier validAvatarId(string memory avatarId) {
        require(bytes(avatarId).length > 0, "Avatar ID cannot be empty");
        _;
    }

    /**
     * @dev Create a new activity script (Goldfire Phase 1 - Basic Activities)
     * @param title Activity title
     * @param description Activity description
     * @param instructions Activity instructions
     * @param activityType Activity Type (PersonalResources, Introductions, Dynamics, Locales, MythicLens, Alchemy, Tales)
     * @param primaryPower Primary power type (required)
     * @param secondaryPowers Array of secondary power types (optional, max 4)
     * @param experienceReward Experience reward
     * @param difficulty Difficulty level (1-10)
     * @param timeLimit Time limit in seconds (0 for no limit)
     * @param maxCompletions Maximum number of completions (0 for unlimited)
     * @param requiresVerification Whether verification is required
     * @param metadata Additional metadata (JSON string for Tales, narrative, etc.)
     * @param authorId Avatar ID or House ID of the author
     * @param decentralizedStorageRef IPFS hash or other decentralized storage reference
     */
    function createActivityScript(
        string memory title,
        string memory description,
        string memory instructions,
        ActivityType activityType,
        PowerType primaryPower,
        PowerType[] memory secondaryPowers,
        uint256 experienceReward,
        uint256 difficulty,
        uint256 timeLimit,
        uint256 maxCompletions,
        bool requiresVerification,
        string memory metadata,
        string memory authorId,
        string memory decentralizedStorageRef
    ) external {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(authorId).length > 0, "Author ID cannot be empty");
        require(experienceReward > 0 && experienceReward <= 1000, "Invalid experience reward");
        require(difficulty >= 1 && difficulty <= 10, "Invalid difficulty");
        require(secondaryPowers.length <= 4, "Too many secondary powers");
        
        // Allow owner or any address (for user-authored activities in future phases)
        // For Phase 1, we can restrict to owner or authorized authors
        require(msg.sender == owner() || bytes(authorId).length > 0, "Not authorized to create activities");
        
        _scriptIds.increment();
        string memory activityId = string(abi.encodePacked("activity-", _scriptIds.current()));
        
        ActivityScript memory newScript = ActivityScript({
            id: activityId,
            title: title,
            description: description,
            instructions: instructions,
            activityType: activityType,
            primaryPower: primaryPower,
            secondaryPowers: secondaryPowers,
            experienceReward: experienceReward,
            difficulty: difficulty,
            timeLimit: timeLimit,
            maxCompletions: maxCompletions,
            completedCount: 0,
            createdAt: block.timestamp,
            isActive: true,
            requiresVerification: requiresVerification,
            metadata: metadata,
            authorId: authorId,
            decentralizedStorageRef: decentralizedStorageRef
        });
        
        activityScripts[activityId] = newScript;
        
        emit ActivityScriptCreated(activityId, title, activityType, primaryPower, experienceReward, authorId, block.timestamp);
    }

    /**
     * @dev Complete an activity script
     * @param activityId Activity script ID
     * @param avatarId Avatar ID completing the activity
     * @param proof Proof of completion (IPFS hash, etc.)
     */
    function completeActivity(
        string memory activityId,
        string memory avatarId,
        string memory proof
    ) external scriptExists(activityId) scriptActive(activityId) notCompleted(activityId, avatarId) validAvatarId(avatarId) {
        ActivityScript storage script = activityScripts[activityId];
        
        // Check completion limits
        if (script.maxCompletions > 0) {
            require(script.completedCount < script.maxCompletions, "Activity completion limit reached");
        }
        
        // Check time limit if applicable
        if (script.timeLimit > 0) {
            require(block.timestamp >= script.createdAt + script.timeLimit, "Activity time limit not reached");
        }
        
        uint256 experienceEarned = script.experienceReward;
        
        if (script.requiresVerification) {
            // Create verification request
            VerificationRequest memory request = VerificationRequest({
                avatarId: avatarId,
                activityId: activityId,
                requestedAt: block.timestamp,
                isPending: true,
                proof: proof
            });
            
            verificationRequests[activityId].push(request);
            
            emit VerificationRequested(activityId, avatarId, proof, block.timestamp);
        } else {
            // Auto-complete and award experience
            _awardCompletion(activityId, avatarId, experienceEarned, proof, address(0));
        }
    }

    /**
     * @dev Verify an activity completion
     * @param activityId Activity script ID
     * @param avatarId Avatar ID to verify
     * @param approved Whether to approve the verification
     * @param adjustedExperience Adjusted experience reward (0 to use default)
     */
    function verifyActivity(
        string memory activityId,
        string memory avatarId,
        bool approved,
        uint256 adjustedExperience
    ) external scriptExists(activityId) isAuthorizedVerifier {
        // Find the verification request
        VerificationRequest[] storage requests = verificationRequests[activityId];
        bool requestFound = false;
        
        for (uint256 i = 0; i < requests.length; i++) {
            if (keccak256(bytes(requests[i].avatarId)) == keccak256(bytes(avatarId)) && requests[i].isPending) {
                requestFound = true;
                requests[i].isPending = false;
                break;
            }
        }
        
        require(requestFound, "Verification request not found");
        
        if (approved) {
            ActivityScript storage script = activityScripts[activityId];
            uint256 experienceEarned = adjustedExperience > 0 ? adjustedExperience : script.experienceReward;
            
            _awardCompletion(activityId, avatarId, experienceEarned, "", msg.sender);
        }
    }

    /**
     * @dev Award completion and experience
     * @param activityId Activity script ID
     * @param avatarId Avatar ID
     * @param experienceEarned Experience to award
     * @param proof Proof of completion
     * @param verifier Address of verifier (address(0) for auto-verification)
     */
    function _awardCompletion(
        string memory activityId,
        string memory avatarId,
        uint256 experienceEarned,
        string memory proof,
        address verifier
    ) internal {
        ActivityScript storage script = activityScripts[activityId];
        
        // Create completion record
        CompletionRecord memory record = CompletionRecord({
            avatarId: avatarId,
            walletAddress: msg.sender,
            completedAt: block.timestamp,
            experienceEarned: experienceEarned,
            proof: proof,
            verified: verifier != address(0),
            verifier: verifier,
            verifiedAt: verifier != address(0) ? block.timestamp : 0
        });
        
        completions[activityId][avatarId] = record;
        activityCompletions[activityId].push(avatarId);
        hasCompleted[activityId][avatarId] = true;
        completionTimestamps[activityId][avatarId] = block.timestamp;
        
        script.completedCount++;
        
        emit ActivityCompleted(activityId, avatarId, msg.sender, experienceEarned, block.timestamp);
        
        if (verifier != address(0)) {
            emit ActivityVerified(activityId, avatarId, verifier, experienceEarned, block.timestamp);
        }
    }

    /**
     * @dev Get activity script information
     * @param activityId Activity script ID
     * @return script Activity script information
     */
    function getActivityScript(string memory activityId) external view scriptExists(activityId) returns (ActivityScript memory script) {
        return activityScripts[activityId];
    }

    /**
     * @dev Get completion record
     * @param activityId Activity script ID
     * @param avatarId Avatar ID
     * @return record Completion record
     */
    function getCompletionRecord(
        string memory activityId,
        string memory avatarId
    ) external view scriptExists(activityId) returns (CompletionRecord memory record) {
        return completions[activityId][avatarId];
    }

    /**
     * @dev Get activity completions
     * @param activityId Activity script ID
     * @return avatarIds Array of avatar IDs who completed the activity
     */
    function getActivityCompletions(string memory activityId) external view scriptExists(activityId) returns (string[] memory avatarIds) {
        return activityCompletions[activityId];
    }

    /**
     * @dev Check if avatar has completed activity
     * @param activityId Activity script ID
     * @param avatarId Avatar ID
     * @return completed Whether the avatar has completed the activity
     */
    function hasCompletedActivity(
        string memory activityId,
        string memory avatarId
    ) external view scriptExists(activityId) returns (bool completed) {
        return hasCompleted[activityId][avatarId];
    }

    /**
     * @dev Get verification requests for an activity
     * @param activityId Activity script ID
     * @return requests Array of verification requests
     */
    function getVerificationRequests(string memory activityId) external view scriptExists(activityId) returns (VerificationRequest[] memory requests) {
        return verificationRequests[activityId];
    }

    /**
     * @dev Authorize or revoke verifier
     * @param verifier Verifier address
     * @param authorized Whether to authorize the verifier
     */
    function setVerifierAuthorization(address verifier, bool authorized) external onlyOwner {
        authorizedVerifiers[verifier] = authorized;
        emit VerifierAuthorized(verifier, authorized, block.timestamp);
    }

    /**
     * @dev Update activity script
     * @param activityId Activity script ID
     * @param title New title
     * @param description New description
     * @param isActive Whether the activity is active
     */
    function updateActivityScript(
        string memory activityId,
        string memory title,
        string memory description,
        bool isActive
    ) external onlyOwner scriptExists(activityId) {
        ActivityScript storage script = activityScripts[activityId];
        if (bytes(title).length > 0) script.title = title;
        if (bytes(description).length > 0) script.description = description;
        script.isActive = isActive;
        
        emit ActivityScriptUpdated(activityId, title, isActive, block.timestamp);
    }

    /**
     * @dev Get activities by power type
     * @param powerType Power type to filter by
     * @return activityIds Array of activity IDs
     */
    function getActivitiesByPower(PowerType powerType) external view returns (string[] memory activityIds) {
        // This would require additional storage or events to track efficiently
        // For now, return empty array - implement with events or additional mapping
        return new string[](0);
    }

    /**
     * @dev Get avatar's completed activities
     * @param avatarId Avatar ID
     * @return activityIds Array of completed activity IDs
     */
    function getAvatarCompletions(string memory avatarId) external view validAvatarId(avatarId) returns (string[] memory activityIds) {
        // This would require additional storage or events to track efficiently
        // For now, return empty array - implement with events or additional mapping
        return new string[](0);
    }

    /**
     * @dev Emergency function to reset activity completion (owner only)
     * @param activityId Activity script ID
     * @param avatarId Avatar ID
     */
    function emergencyResetCompletion(
        string memory activityId,
        string memory avatarId
    ) external onlyOwner scriptExists(activityId) {
        if (hasCompleted[activityId][avatarId]) {
            delete completions[activityId][avatarId];
            delete hasCompleted[activityId][avatarId];
            delete completionTimestamps[activityId][avatarId];
            
            // Remove from completions list
            string[] storage completionList = activityCompletions[activityId];
            for (uint256 i = 0; i < completionList.length; i++) {
                if (keccak256(bytes(completionList[i])) == keccak256(bytes(avatarId))) {
                    completionList[i] = completionList[completionList.length - 1];
                    completionList.pop();
                    break;
                }
            }
            
            activityScripts[activityId].completedCount--;
        }
    }
} 