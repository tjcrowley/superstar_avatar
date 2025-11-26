// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title SimpleAccountFactory
 * @dev ERC-4337 compliant account factory for creating smart contract accounts
 * @dev Creates deterministic addresses for user accounts
 * @dev Upgradeable using UUPS proxy pattern
 */
contract SimpleAccountFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // EntryPoint address
    address public entryPoint;
    
    // Account implementation address (will be set after deployment)
    address public accountImplementation;
    
    // Mapping of owner to account address
    mapping(address => address) public accounts;
    
    // Events
    event AccountCreated(address indexed owner, address indexed account, uint256 timestamp);
    event EntryPointUpdated(address indexed oldEntryPoint, address indexed newEntryPoint);
    event AccountImplementationUpdated(address indexed oldImpl, address indexed newImpl);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _entryPoint) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        require(_entryPoint != address(0), "Invalid EntryPoint");
        entryPoint = _entryPoint;
        emit EntryPointUpdated(address(0), _entryPoint);
    }

    /**
     * @dev Set the account implementation address
     * @param _accountImplementation Address of the account implementation contract
     */
    function setAccountImplementation(address _accountImplementation) external onlyOwner {
        address oldImpl = accountImplementation;
        accountImplementation = _accountImplementation;
        emit AccountImplementationUpdated(oldImpl, _accountImplementation);
    }

    /**
     * @dev Create a new account for a user
     * @param owner The owner address (EOA)
     * @param salt Optional salt for deterministic address generation
     * @return account The created account address
     */
    function createAccount(address owner, uint256 salt) external returns (address account) {
        require(owner != address(0), "Invalid owner");
        require(accountImplementation != address(0), "Account implementation not set");
        require(accounts[owner] == address(0), "Account already exists");
        
        // Create deterministic address
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            accountImplementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        
        account = address(uint160(uint256(hash)));
        
        // Deploy the account
        assembly {
            account := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        require(account != address(0), "Account creation failed");
        
        accounts[owner] = account;
        emit AccountCreated(owner, account, block.timestamp);
        
        return account;
    }

    /**
     * @dev Get account address for an owner
     * @param owner The owner address
     * @return account The account address (address(0) if not created)
     */
    function getAccount(address owner) external view returns (address account) {
        return accounts[owner];
    }

    /**
     * @dev Check if an account exists for an owner
     * @param owner The owner address
     * @return True if account exists
     */
    function hasAccount(address owner) external view returns (bool) {
        return accounts[owner] != address(0);
    }

    /**
     * @dev Update EntryPoint address (owner only)
     * @param _entryPoint New EntryPoint address
     */
    function setEntryPoint(address _entryPoint) external onlyOwner {
        require(_entryPoint != address(0), "Invalid EntryPoint");
        address oldEntryPoint = entryPoint;
        entryPoint = _entryPoint;
        emit EntryPointUpdated(oldEntryPoint, _entryPoint);
    }

    /**
     * @dev Authorize upgrade (only owner)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

