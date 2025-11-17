// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title AvatarRegistry
 * @dev Manages avatar profiles on-chain with upgradable proxy pattern
 * @dev Stores avatar metadata including name, bio, image URI, and wallet address
 */
contract AvatarRegistry is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    // Avatar profile structure
    struct AvatarProfile {
        string id;                    // Unique avatar ID
        string name;                   // Avatar name
        string bio;                    // Avatar biography
        string imageUri;               // IPFS hash or image URI (updatable)
        address walletAddress;         // Associated wallet address
        uint256 createdAt;             // Creation timestamp
        uint256 updatedAt;             // Last update timestamp
        bool isActive;                 // Active status
        string metadata;               // Additional JSON metadata
    }

    // Mappings
    mapping(string => AvatarProfile) public avatars;              // avatarId => AvatarProfile
    mapping(address => string) public addressToAvatarId;         // walletAddress => avatarId
    mapping(string => bool) public avatarIdExists;              // avatarId => exists

    // Events
    event AvatarCreated(
        string indexed avatarId,
        address indexed walletAddress,
        string name,
        string imageUri,
        uint256 timestamp
    );

    event AvatarUpdated(
        string indexed avatarId,
        address indexed walletAddress,
        string name,
        string imageUri,
        uint256 timestamp
    );

    event AvatarImageUpdated(
        string indexed avatarId,
        string oldImageUri,
        string newImageUri,
        uint256 timestamp
    );

    event AvatarDeactivated(
        string indexed avatarId,
        address indexed walletAddress,
        uint256 timestamp
    );

    // Modifiers
    modifier avatarExists(string memory avatarId) {
        require(avatarIdExists[avatarId], "Avatar does not exist");
        _;
    }

    modifier validAvatarId(string memory avatarId) {
        require(bytes(avatarId).length > 0, "Avatar ID cannot be empty");
        _;
    }

    modifier onlyAvatarOwner(string memory avatarId) {
        require(
            avatars[avatarId].walletAddress == msg.sender,
            "Not the avatar owner"
        );
        _;
    }

    /**
     * @dev Initialize the contract (replaces constructor for upgradeable contracts)
     * @param initialOwner Address of the contract owner
     */
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
    }

    /**
     * @dev Create a new avatar profile
     * @param avatarId Unique avatar ID
     * @param name Avatar name
     * @param bio Avatar biography
     * @param imageUri IPFS hash or image URI
     * @param metadata Additional JSON metadata
     */
    function createAvatar(
        string memory avatarId,
        string memory name,
        string memory bio,
        string memory imageUri,
        string memory metadata
    ) external validAvatarId(avatarId) nonReentrant {
        require(!avatarIdExists[avatarId], "Avatar ID already exists");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(
            bytes(addressToAvatarId[msg.sender]).length == 0,
            "Wallet already has an avatar"
        );

        AvatarProfile memory newAvatar = AvatarProfile({
            id: avatarId,
            name: name,
            bio: bio,
            imageUri: imageUri,
            walletAddress: msg.sender,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true,
            metadata: metadata
        });

        avatars[avatarId] = newAvatar;
        addressToAvatarId[msg.sender] = avatarId;
        avatarIdExists[avatarId] = true;

        emit AvatarCreated(
            avatarId,
            msg.sender,
            name,
            imageUri,
            block.timestamp
        );
    }

    /**
     * @dev Update avatar profile (name, bio, metadata)
     * @param avatarId Avatar ID
     * @param name New avatar name (empty string to keep current)
     * @param bio New avatar bio (empty string to keep current)
     * @param metadata New metadata (empty string to keep current)
     */
    function updateAvatar(
        string memory avatarId,
        string memory name,
        string memory bio,
        string memory metadata
    ) external avatarExists(avatarId) onlyAvatarOwner(avatarId) nonReentrant {
        AvatarProfile storage avatar = avatars[avatarId];
        require(avatar.isActive, "Avatar is not active");

        if (bytes(name).length > 0) {
            avatar.name = name;
        }
        if (bytes(bio).length > 0) {
            avatar.bio = bio;
        }
        if (bytes(metadata).length > 0) {
            avatar.metadata = metadata;
        }
        avatar.updatedAt = block.timestamp;

        emit AvatarUpdated(
            avatarId,
            msg.sender,
            avatar.name,
            avatar.imageUri,
            block.timestamp
        );
    }

    /**
     * @dev Update avatar image URI
     * @param avatarId Avatar ID
     * @param newImageUri New IPFS hash or image URI
     */
    function updateAvatarImage(
        string memory avatarId,
        string memory newImageUri
    ) external avatarExists(avatarId) onlyAvatarOwner(avatarId) nonReentrant {
        AvatarProfile storage avatar = avatars[avatarId];
        require(avatar.isActive, "Avatar is not active");
        require(bytes(newImageUri).length > 0, "Image URI cannot be empty");

        string memory oldImageUri = avatar.imageUri;
        avatar.imageUri = newImageUri;
        avatar.updatedAt = block.timestamp;

        emit AvatarImageUpdated(
            avatarId,
            oldImageUri,
            newImageUri,
            block.timestamp
        );

        emit AvatarUpdated(
            avatarId,
            msg.sender,
            avatar.name,
            newImageUri,
            block.timestamp
        );
    }

    /**
     * @dev Get avatar profile by ID
     * @param avatarId Avatar ID
     * @return AvatarProfile struct
     */
    function getAvatar(string memory avatarId)
        external
        view
        avatarExists(avatarId)
        returns (AvatarProfile memory)
    {
        return avatars[avatarId];
    }

    /**
     * @dev Get avatar ID by wallet address
     * @param walletAddress Wallet address
     * @return avatarId Avatar ID (empty string if not found)
     */
    function getAvatarIdByAddress(address walletAddress)
        external
        view
        returns (string memory)
    {
        return addressToAvatarId[walletAddress];
    }

    /**
     * @dev Check if avatar exists
     * @param avatarId Avatar ID
     * @return exists True if avatar exists
     */
    function avatarExistsCheck(string memory avatarId)
        external
        view
        returns (bool)
    {
        return avatarIdExists[avatarId];
    }

    /**
     * @dev Deactivate avatar (owner only, for moderation)
     * @param avatarId Avatar ID
     */
    function deactivateAvatar(string memory avatarId)
        external
        avatarExists(avatarId)
        onlyOwner
    {
        avatars[avatarId].isActive = false;
        emit AvatarDeactivated(
            avatarId,
            avatars[avatarId].walletAddress,
            block.timestamp
        );
    }

    /**
     * @dev Reactivate avatar (owner only)
     * @param avatarId Avatar ID
     */
    function reactivateAvatar(string memory avatarId)
        external
        avatarExists(avatarId)
        onlyOwner
    {
        avatars[avatarId].isActive = true;
        avatars[avatarId].updatedAt = block.timestamp;
        emit AvatarUpdated(
            avatarId,
            avatars[avatarId].walletAddress,
            avatars[avatarId].name,
            avatars[avatarId].imageUri,
            block.timestamp
        );
    }
}

