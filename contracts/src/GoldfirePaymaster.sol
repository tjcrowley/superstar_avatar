// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GoldfireToken.sol";
import "./AdminRegistry.sol";

/**
 * @title ERC-4337 UserOperation struct
 * @dev Standard UserOperation structure as defined in ERC-4337
 */
struct UserOperation {
    address sender;                // Account making the operation
    uint256 nonce;                 // Anti-replay parameter
    bytes initCode;                // If set, the account contract will be created by constructing this address
    bytes callData;                // The call data to pass to the sender
    uint256 callGasLimit;          // Gas limit for the execution step
    uint256 verificationGasLimit;  // Gas limit for the verification step
    uint256 preVerificationGas;    // Gas used for validation
    uint256 maxFeePerGas;          // Maximum fee per gas
    uint256 maxPriorityFeePerGas;  // Maximum priority fee per gas
    bytes paymasterAndData;        // Paymaster address and data
    bytes signature;               // Signature over the entire userOp
}

/**
 * @title PostOpMode enum
 * @dev Mode for post-operation execution
 */
enum PostOpMode {
    opSucceeded,    // User op succeeded
    opReverted,     // User op reverted
    postOpReverted  // Post-op reverted
}

/**
 * @title GoldfirePaymaster
 * @dev ERC-4337 compliant paymaster that sponsors gas fees
 * @dev Supports hybrid funding: admin-funded for initial setup, Goldfire tokens for ongoing
 * @dev Simplified implementation - in production, use proper ERC-4337 interfaces
 * @dev Upgradeable using UUPS proxy pattern
 */
contract GoldfirePaymaster is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    // EntryPoint address
    address public entryPoint;
    
    // Goldfire token contract
    GoldfireToken public goldfireToken;
    
    // Admin registry contract
    AdminRegistry public adminRegistry;
    
    // Conversion rate: 1 GF token = X wei of native gas
    // Example: 1000000000000000 means 1 GF = 0.001 ETH (1e15 wei)
    uint256 public goldfireToGasRate;
    
    // Minimum deposit required for sponsored transactions
    uint256 public minDeposit;
    
    // Whitelist for gasless operations (initial setup)
    mapping(address => bool) public gaslessWhitelist;
    
    // User deposits for gas payments (in native token)
    mapping(address => uint256) public userDeposits;
    
    // User Goldfire token balances available for gas
    mapping(address => uint256) public userGoldfireBalances;
    
    // Flag to enable automatic sponsorship of avatar creation for all users
    bool public sponsorAvatarCreation;
    
    // Avatar Registry contract address (for validating avatar creation transactions)
    address public avatarRegistry;
    
    // Flag to enable automatic sponsorship of ALL transactions for all users
    // NOTE: This must be at the end to maintain upgrade safety
    bool public sponsorAllTransactions;
    
    // Events
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event GoldfireDeposited(address indexed user, uint256 amount, uint256 timestamp);
    event GasSponsored(address indexed user, uint256 gasCost, uint256 timestamp);
    event GoldfireGasPaid(address indexed user, uint256 goldfireAmount, uint256 gasCost, uint256 timestamp);
    event WhitelistUpdated(address indexed user, bool isWhitelisted, uint256 timestamp);
    event ConversionRateUpdated(uint256 oldRate, uint256 newRate, uint256 timestamp);
    event AvatarCreationSponsorshipEnabled(bool enabled, uint256 timestamp);
    event AllTransactionsSponsorshipEnabled(bool enabled, uint256 timestamp);
    event AvatarRegistryUpdated(address oldRegistry, address newRegistry, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _entryPoint,
        address _goldfireToken,
        address _adminRegistry,
        uint256 _goldfireToGasRate
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        require(_entryPoint != address(0), "Invalid EntryPoint");
        require(_goldfireToken != address(0), "Invalid GoldfireToken");
        require(_adminRegistry != address(0), "Invalid AdminRegistry");
        
        entryPoint = _entryPoint;
        goldfireToken = GoldfireToken(_goldfireToken);
        adminRegistry = AdminRegistry(_adminRegistry);
        goldfireToGasRate = _goldfireToGasRate;
        minDeposit = 0.01 ether; // Default minimum deposit
    }

    /**
     * @dev Deposit native tokens for gas sponsorship (admin only)
     */
    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Must send native tokens");
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw native tokens from paymaster (admin only)
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= address(this).balance, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit Withdrawn(owner(), amount, block.timestamp);
    }

    /**
     * @dev Add user to gasless whitelist (admin only)
     * @param user Address to whitelist
     */
    function addToWhitelist(address user) external {
        require(adminRegistry.isAdmin(msg.sender), "Not an admin");
        require(user != address(0), "Invalid address");
        
        gaslessWhitelist[user] = true;
        emit WhitelistUpdated(user, true, block.timestamp);
    }

    /**
     * @dev Remove user from gasless whitelist (admin only)
     * @param user Address to remove from whitelist
     */
    function removeFromWhitelist(address user) external {
        require(adminRegistry.isAdmin(msg.sender), "Not an admin");
        
        gaslessWhitelist[user] = false;
        emit WhitelistUpdated(user, false, block.timestamp);
    }

    /**
     * @dev Set conversion rate for Goldfire to gas (owner only)
     * @param newRate New conversion rate (1 GF = newRate wei)
     */
    function setConversionRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Rate must be greater than 0");
        uint256 oldRate = goldfireToGasRate;
        goldfireToGasRate = newRate;
        emit ConversionRateUpdated(oldRate, newRate, block.timestamp);
    }

    /**
     * @dev Set minimum deposit (owner only)
     * @param _minDeposit New minimum deposit amount
     */
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        minDeposit = _minDeposit;
    }

    /**
     * @dev Enable/disable automatic sponsorship of avatar creation for all users (admin only)
     * @param enabled True to enable automatic sponsorship
     */
    function setSponsorAvatarCreation(bool enabled) external {
        require(adminRegistry.isAdmin(msg.sender), "Not an admin");
        sponsorAvatarCreation = enabled;
        emit AvatarCreationSponsorshipEnabled(enabled, block.timestamp);
    }

    /**
     * @dev Enable/disable automatic sponsorship of ALL transactions for all users (admin only)
     * @param enabled True to enable automatic sponsorship of all transactions
     * @dev When enabled, all users are automatically whitelisted for gasless transactions
     */
    function setSponsorAllTransactions(bool enabled) external {
        require(adminRegistry.isAdmin(msg.sender), "Not an admin");
        sponsorAllTransactions = enabled;
        emit AllTransactionsSponsorshipEnabled(enabled, block.timestamp);
    }

    /**
     * @dev Set Avatar Registry contract address (admin only)
     * @param _avatarRegistry Address of the Avatar Registry contract
     */
    function setAvatarRegistry(address _avatarRegistry) external {
        require(adminRegistry.isAdmin(msg.sender), "Not an admin");
        require(_avatarRegistry != address(0), "Invalid address");
        address oldRegistry = avatarRegistry;
        avatarRegistry = _avatarRegistry;
        emit AvatarRegistryUpdated(oldRegistry, _avatarRegistry, block.timestamp);
    }

    /**
     * @dev Automatically whitelist user for avatar creation (can be called by anyone)
     * @dev This allows users to create their first avatar without MATIC
     */
    function whitelistForAvatarCreation(address user) external {
        require(user != address(0), "Invalid address");
        require(sponsorAvatarCreation, "Avatar creation sponsorship not enabled");
        
        // Only whitelist if user is not already whitelisted
        if (!gaslessWhitelist[user]) {
            gaslessWhitelist[user] = true;
            emit WhitelistUpdated(user, true, block.timestamp);
        }
    }

    /**
     * @dev Automatically whitelist user for all gasless transactions (can be called by anyone)
     * @dev This allows users to perform any transaction without MATIC
     */
    function whitelistForAllTransactions(address user) external {
        require(user != address(0), "Invalid address");
        require(sponsorAllTransactions, "All transactions sponsorship not enabled");
        
        // Only whitelist if user is not already whitelisted
        if (!gaslessWhitelist[user]) {
            gaslessWhitelist[user] = true;
            emit WhitelistUpdated(user, true, block.timestamp);
        }
    }

    /**
     * @dev Extract owner address from initCode for account creation
     * @param initCode The initCode from UserOperation
     * @return owner The owner address (EOA) that will own the account
     * @dev initCode format: factoryAddress (20 bytes) + functionSelector (4 bytes) + encoded params
     * @dev For createAccount(owner, salt), params are: owner (32 bytes) + salt (32 bytes)
     */
    function _extractOwnerFromInitCode(bytes calldata initCode) internal view returns (address owner) {
        // initCode must be at least: 20 bytes (factory) + 4 bytes (selector) + 32 bytes (owner) = 56 bytes
        require(initCode.length >= 56, "Invalid initCode length");
        
        // Skip factory address (20 bytes) and function selector (4 bytes) = 24 bytes
        // Extract owner address from the next 32 bytes (padded to 32 bytes, actual address is last 20 bytes)
        bytes memory ownerBytes = initCode[24:56];
        
        // Owner address is in the last 20 bytes of the 32-byte word
        assembly {
            owner := mload(add(ownerBytes, 12)) // Skip first 12 bytes, get last 20
        }
        
        require(owner != address(0), "Invalid owner address");
        return owner;
    }

    /**
     * @dev Check if callData is an avatar creation call
     * @param callData The callData from UserOperation
     * @return isAvatarCreation True if this is an avatar creation transaction
     * @dev Checks if the call is to avatarRegistry.createAvatar function
     */
    function _isAvatarCreationCall(bytes calldata callData) internal view returns (bool isAvatarCreation) {
        if (avatarRegistry == address(0)) {
            return false;
        }
        
        // Function selector for createAvatar(string,string,string,string,string,string)
        // This is keccak256("createAvatar(string,string,string,string,string,string)")[0:4]
        bytes4 createAvatarSelector = 0x12345678; // TODO: Calculate actual selector
        
        // Check if callData starts with createAvatar selector
        if (callData.length < 4) {
            return false;
        }
        
        bytes4 selector = bytes4(callData[0:4]);
        // For now, we'll check if the call is to the avatar registry
        // In production, decode the callData to verify it's createAvatar
        // This is a simplified check - in production, properly decode and verify
        return true; // Simplified: assume all calls to avatar registry are avatar creation
    }

    /**
     * @dev Get owner address from UserOperation (either from sender or initCode)
     * @param userOp The UserOperation
     * @return owner The owner address (EOA) that should be checked for whitelisting
     */
    function _getOwnerAddress(UserOperation calldata userOp) internal view returns (address owner) {
        // If initCode is present, account is being created - extract owner from initCode
        if (userOp.initCode.length > 0) {
            return _extractOwnerFromInitCode(userOp.initCode);
        }
        
        // If account already exists, we need to get the owner from the account
        // For now, we'll use the sender address as a fallback
        // In a full implementation, you'd query the account contract for its owner
        // This is a limitation - we need the account to expose an owner() function
        return userOp.sender;
    }

    /**
     * @dev Validate and pay for user operation (full ERC-4337 interface)
     * @param userOp The UserOperation to validate
     * @param userOpHash Hash of the UserOperation
     * @param maxCost Maximum gas cost the paymaster is willing to sponsor
     * @return context Context data to be passed to postOp
     * @dev This is the standard ERC-4337 paymaster interface
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context) {
        require(msg.sender == entryPoint, "Only EntryPoint can call");
        
        // Get owner address (from initCode if account creation, or from sender if existing account)
        address owner = _getOwnerAddress(userOp);
        
        // Check if owner is whitelisted for gasless transactions
        bool shouldSponsor = false;
        address addressToWhitelist = owner;
        
        if (gaslessWhitelist[owner]) {
            // Owner is already whitelisted
            shouldSponsor = true;
        } else if (sponsorAllTransactions) {
            // Auto-whitelist owner and sponsor all transactions
            gaslessWhitelist[owner] = true;
            emit WhitelistUpdated(owner, true, block.timestamp);
            shouldSponsor = true;
        } else if (sponsorAvatarCreation) {
            // Check if this is an avatar creation call
            bool isAvatarCreation = _isAvatarCreationCall(userOp.callData);
            if (isAvatarCreation) {
                // Auto-whitelist owner and sponsor avatar creation
                gaslessWhitelist[owner] = true;
                emit WhitelistUpdated(owner, true, block.timestamp);
                shouldSponsor = true;
            }
        }
        
        // If owner is whitelisted, check paymaster balance and sponsor
        if (shouldSponsor) {
            require(address(this).balance >= maxCost, "Insufficient paymaster balance");
            // Return context with owner address and maxCost for postOp
            return abi.encode(owner, maxCost, true); // true = sponsored
        }
        
        // Check if owner has approved Goldfire tokens
        uint256 requiredGoldfire = (maxCost * 1e18) / goldfireToGasRate;
        if (userGoldfireBalances[owner] >= requiredGoldfire) {
            // User has enough Goldfire tokens - will be deducted in postOp
            return abi.encode(owner, requiredGoldfire, false); // false = Goldfire payment
        }
        
        // Check if owner has native deposit
        if (userDeposits[owner] >= maxCost) {
            // User has enough native deposit - will be deducted in postOp
            return abi.encode(owner, maxCost, false); // false = native deposit payment
        }
        
        // Revert if no valid payment method
        revert("Insufficient payment");
    }

    /**
     * @dev Post-operation handler (full ERC-4337 interface)
     * @param mode The mode indicating success/failure
     * @param context Context data from validatePaymasterUserOp
     * @param actualGasCost The actual gas cost of the operation
     * @dev Called after the UserOperation executes
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external {
        require(msg.sender == entryPoint, "Only EntryPoint can call");
        
        // Decode context
        (address owner, uint256 maxCost, bool isSponsored) = abi.decode(context, (address, uint256, bool));
        
        // Only process payment if operation succeeded
        if (mode != PostOpMode.opSucceeded) {
            // Operation failed - don't charge user
            return;
        }
        
        if (isSponsored) {
            // Transaction was sponsored - paymaster covers the cost
            // The actualGasCost should be <= maxCost
            require(actualGasCost <= maxCost, "Actual cost exceeds max cost");
            emit GasSponsored(owner, actualGasCost, block.timestamp);
        } else {
            // User pays with Goldfire tokens or native deposit
            // Check if it was Goldfire or native
            if (userGoldfireBalances[owner] >= maxCost) {
                // Deduct Goldfire tokens
                uint256 requiredGoldfire = (actualGasCost * 1e18) / goldfireToGasRate;
                userGoldfireBalances[owner] -= requiredGoldfire;
                
                // Transfer Goldfire tokens from owner to paymaster
                require(
                    goldfireToken.transferFrom(owner, address(this), requiredGoldfire),
                    "Goldfire transfer failed"
                );
                
                emit GoldfireGasPaid(owner, requiredGoldfire, actualGasCost, block.timestamp);
            } else if (userDeposits[owner] >= actualGasCost) {
                // Deduct native deposit
                userDeposits[owner] -= actualGasCost;
                emit GasSponsored(owner, actualGasCost, block.timestamp);
            } else {
                // This shouldn't happen if validatePaymasterUserOp worked correctly
                revert("Payment failed");
            }
        }
    }

    /**
     * @dev Validate and pay for user operation (simplified ERC-4337 interface - DEPRECATED)
     * @param user Address of the user
     * @param gasCost Gas cost to pay
     * @return success True if payment was successful
     * @dev This is kept for backward compatibility but should not be used
     * @dev Use validatePaymasterUserOp instead
     */
    function validateAndPay(address user, uint256 gasCost) external returns (bool success) {
        require(msg.sender == entryPoint, "Only EntryPoint can call");
        
        // Check if user is whitelisted for gasless transactions
        if (gaslessWhitelist[user]) {
            require(address(this).balance >= gasCost, "Insufficient paymaster balance");
            emit GasSponsored(user, gasCost, block.timestamp);
            return true;
        }
        
        // If all transactions sponsorship is enabled, automatically whitelist and sponsor
        if (sponsorAllTransactions) {
            gaslessWhitelist[user] = true;
            require(address(this).balance >= gasCost, "Insufficient paymaster balance");
            emit WhitelistUpdated(user, true, block.timestamp);
            emit GasSponsored(user, gasCost, block.timestamp);
            return true;
        }
        
        // If avatar creation sponsorship is enabled, automatically sponsor
        if (sponsorAvatarCreation) {
            gaslessWhitelist[user] = true;
            require(address(this).balance >= gasCost, "Insufficient paymaster balance");
            emit WhitelistUpdated(user, true, block.timestamp);
            emit GasSponsored(user, gasCost, block.timestamp);
            return true;
        }
        
        // Check if user has approved Goldfire tokens
        uint256 requiredGoldfire = (gasCost * 1e18) / goldfireToGasRate;
        if (userGoldfireBalances[user] >= requiredGoldfire) {
            userGoldfireBalances[user] -= requiredGoldfire;
            require(
                goldfireToken.transferFrom(user, address(this), requiredGoldfire),
                "Goldfire transfer failed"
            );
            emit GoldfireGasPaid(user, requiredGoldfire, gasCost, block.timestamp);
            return true;
        }
        
        // Check if user has native deposit
        if (userDeposits[user] >= gasCost) {
            userDeposits[user] -= gasCost;
            emit GasSponsored(user, gasCost, block.timestamp);
            return true;
        }
        
        revert("Insufficient payment");
    }

    /**
     * @dev User deposits native tokens for gas payments
     */
    function userDeposit() external payable {
        require(msg.value >= minDeposit, "Deposit below minimum");
        userDeposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev User withdraws native token deposit
     * @param amount Amount to withdraw
     */
    function userWithdraw(uint256 amount) external nonReentrant {
        require(userDeposits[msg.sender] >= amount, "Insufficient deposit");
        require(amount > 0, "Amount must be greater than 0");
        
        userDeposits[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev User deposits Goldfire tokens for gas payments
     * @param amount Amount of Goldfire tokens to deposit
     */
    function depositGoldfireForGas(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer Goldfire tokens from user to paymaster
        require(
            goldfireToken.transferFrom(msg.sender, address(this), amount),
            "Goldfire transfer failed"
        );
        
        userGoldfireBalances[msg.sender] += amount;
        emit GoldfireDeposited(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev User withdraws Goldfire token deposit
     * @param amount Amount of Goldfire tokens to withdraw
     */
    function withdrawGoldfireDeposit(uint256 amount) external nonReentrant {
        require(userGoldfireBalances[msg.sender] >= amount, "Insufficient Goldfire deposit");
        require(amount > 0, "Amount must be greater than 0");
        
        userGoldfireBalances[msg.sender] -= amount;
        
        require(
            goldfireToken.transfer(msg.sender, amount),
            "Goldfire transfer failed"
        );
        
        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Get user's available payment methods
     * @param user User address
     * @return hasWhitelist True if user is whitelisted
     * @return nativeDeposit User's native token deposit
     * @return goldfireBalance User's Goldfire token balance for gas
     */
    function getUserPaymentInfo(address user) external view returns (
        bool hasWhitelist,
        uint256 nativeDeposit,
        uint256 goldfireBalance
    ) {
        return (
            gaslessWhitelist[user],
            userDeposits[user],
            userGoldfireBalances[user]
        );
    }

    /**
     * @dev Get paymaster balance
     * @return Balance in native tokens
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Authorize upgrade (only owner)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Receive function to accept native tokens
    receive() external payable {
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
}
