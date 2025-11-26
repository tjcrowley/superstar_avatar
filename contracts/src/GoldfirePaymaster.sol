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
    
    // Events
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event GoldfireDeposited(address indexed user, uint256 amount, uint256 timestamp);
    event GasSponsored(address indexed user, uint256 gasCost, uint256 timestamp);
    event GoldfireGasPaid(address indexed user, uint256 goldfireAmount, uint256 gasCost, uint256 timestamp);
    event WhitelistUpdated(address indexed user, bool isWhitelisted, uint256 timestamp);
    event ConversionRateUpdated(uint256 oldRate, uint256 newRate, uint256 timestamp);

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
     * @dev Validate and pay for user operation (simplified ERC-4337 interface)
     * @param user Address of the user
     * @param gasCost Gas cost to pay
     * @return success True if payment was successful
     */
    function validateAndPay(address user, uint256 gasCost) external returns (bool success) {
        require(msg.sender == entryPoint, "Only EntryPoint can call");
        
        // Check if user is whitelisted for gasless transactions
        if (gaslessWhitelist[user]) {
            // Gasless transaction - sponsored by admin
            require(address(this).balance >= gasCost, "Insufficient paymaster balance");
            emit GasSponsored(user, gasCost, block.timestamp);
            return true;
        }
        
        // Check if user has approved Goldfire tokens
        uint256 requiredGoldfire = (gasCost * 1e18) / goldfireToGasRate;
        
        if (userGoldfireBalances[user] >= requiredGoldfire) {
            // User has enough Goldfire tokens
            userGoldfireBalances[user] -= requiredGoldfire;
            
            // Transfer Goldfire tokens from user to paymaster
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
        
        // Revert if no valid payment method
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
