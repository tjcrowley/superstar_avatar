// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title AdminRegistry
 * @dev On-chain registry for admin addresses with role-based access control
 * @dev Upgradeable using UUPS proxy pattern
 */
contract AdminRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Mapping of admin addresses to their admin status
    mapping(address => bool) public isAdmin;
    
    // Array of all admin addresses for enumeration
    address[] public adminList;
    
    // Events
    event AdminAdded(address indexed admin, address indexed addedBy, uint256 timestamp);
    event AdminRemoved(address indexed admin, address indexed removedBy, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        // Owner is automatically an admin
        isAdmin[msg.sender] = true;
        adminList.push(msg.sender);
        emit AdminAdded(msg.sender, msg.sender, block.timestamp);
    }

    /**
     * @dev Add an admin address (owner only)
     * @param admin Address to add as admin
     */
    function addAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        require(!isAdmin[admin], "Address is already an admin");
        
        isAdmin[admin] = true;
        adminList.push(admin);
        
        emit AdminAdded(admin, msg.sender, block.timestamp);
    }

    /**
     * @dev Remove an admin address (owner only)
     * @param admin Address to remove from admins
     */
    function removeAdmin(address admin) external onlyOwner {
        require(isAdmin[admin], "Address is not an admin");
        require(admin != owner(), "Cannot remove contract owner");
        
        isAdmin[admin] = false;
        
        // Remove from adminList array
        for (uint256 i = 0; i < adminList.length; i++) {
            if (adminList[i] == admin) {
                adminList[i] = adminList[adminList.length - 1];
                adminList.pop();
                break;
            }
        }
        
        emit AdminRemoved(admin, msg.sender, block.timestamp);
    }

    /**
     * @dev Check if an address is an admin
     * @param account Address to check
     * @return True if address is an admin
     */
    function checkAdmin(address account) external view returns (bool) {
        return isAdmin[account];
    }

    /**
     * @dev Get total number of admins
     * @return Number of admins
     */
    function getAdminCount() external view returns (uint256) {
        return adminList.length;
    }

    /**
     * @dev Get all admin addresses
     * @return Array of admin addresses
     */
    function getAllAdmins() external view returns (address[] memory) {
        return adminList;
    }

    /**
     * @dev Modifier to restrict access to admins only
     */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not an admin");
        _;
    }

    /**
     * @dev Authorize upgrade (only owner)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

