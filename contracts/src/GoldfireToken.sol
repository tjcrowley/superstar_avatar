// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title GoldfireToken
 * @dev ERC-20 token for Superstar Avatar rewards and gas payments
 * @dev Token name: Goldfire, Symbol: GF, Decimals: 18
 * @dev Upgradeable using UUPS proxy pattern
 */
contract GoldfireToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("Goldfire", "GF");
        __ERC20Burnable_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    // Authorized minters (contracts that can mint tokens)
    mapping(address => bool) public authorizedMinters;

    /**
     * @dev Set authorized minter (owner only)
     * @param minter Address of contract that can mint tokens
     * @param authorized Whether the minter is authorized
     */
    function setAuthorizedMinter(address minter, bool authorized) external onlyOwner {
        authorizedMinters[minter] = authorized;
        emit AuthorizedMinterUpdated(minter, authorized, block.timestamp);
    }

    /**
     * @dev Mint tokens to a specific address (owner only)
     * @param to Address to receive the tokens
     * @param amount Amount of tokens to mint (in wei, 18 decimals)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount, block.timestamp);
    }

    /**
     * @dev Mint tokens by authorized minter (for activity rewards)
     * @param to Address to receive the tokens
     * @param amount Amount of tokens to mint (in wei, 18 decimals)
     */
    function mintByAuthorized(address to, uint256 amount) external {
        require(authorizedMinters[msg.sender], "Not an authorized minter");
        _mint(to, amount);
        emit TokensMinted(to, amount, block.timestamp);
    }

    /**
     * @dev Batch mint tokens to multiple addresses (owner only)
     * @param recipients Array of addresses to receive tokens
     * @param amounts Array of amounts to mint (must match recipients length)
     */
    function batchMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
            emit TokensMinted(recipients[i], amounts[i], block.timestamp);
        }
    }

    /**
     * @dev Get total supply of tokens
     * @return Total supply
     */
    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev Get balance of an address
     * @param account Address to check
     * @return Balance
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return super.balanceOf(account);
    }

    /**
     * @dev Authorize upgrade (only owner)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Events
    event TokensMinted(address indexed to, uint256 amount, uint256 timestamp);
    event TokensBurned(address indexed from, uint256 amount, uint256 timestamp);
    event AuthorizedMinterUpdated(address indexed minter, bool authorized, uint256 timestamp);
}

