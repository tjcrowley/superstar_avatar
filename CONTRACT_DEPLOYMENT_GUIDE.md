# Contract Deployment Guide

This guide covers deploying all Superstar Avatar smart contracts, including upgradeable contracts using the UUPS proxy pattern.

## Prerequisites

1. **Node.js** (v16 or higher)
2. **npm** or **yarn**
3. **Wallet with MATIC** for gas fees
4. **Polygonscan API key** (optional, for verification)

## Step 1: Environment Setup

### 1.1 Install Dependencies

```bash
cd contracts
npm install
```

### 1.2 Create `.env` File

Create a `.env` file in the `contracts` directory:

```env
# Private key of deployment wallet (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# RPC URLs
POLYGON_RPC_URL=https://polygon-rpc.com
AMOY_RPC_URL=https://rpc-amoy.polygon.technology

# API Keys (optional)
POLYGONSCAN_API_KEY=your_polygonscan_api_key
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key

# ERC-4337 EntryPoint (for Account Abstraction)
# Mainnet: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
# Amoy: Check Polygon documentation
ENTRY_POINT_ADDRESS=0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789

# Optional: Initial paymaster funding (in MATIC)
PAYMASTER_INITIAL_FUNDING=0.1
```

### 1.3 Get Testnet MATIC (for Amoy)

Get testnet MATIC from:
- https://faucet.polygon.technology/ (select Amoy)
- https://www.alchemy.com/faucets/polygon-amoy

## Step 2: Compile Contracts

```bash
npm run compile
```

This compiles all contracts and checks for errors.

## Step 3: Deployment Order

Contracts have dependencies. Deploy in this order:

### Phase 1: Core Contracts (No Dependencies)

1. **GoldfireToken** - ERC-20 token
2. **AdminRegistry** - Admin management
3. **EventProducer** - Event producer registry
4. **PowerVerification** - Power progression
5. **ActivityScripts** - Activity management
6. **SuperstarAvatarRegistry** - Avatar achievements (non-upgradeable)

### Phase 2: Dependent Contracts

7. **EventListings** - Requires EventProducer
8. **Ticketing** - Requires EventListings and EventProducer
9. **HouseMembership** - Requires GoldfireToken, EventProducer, EventListings
10. **AvatarRegistry** - Standalone upgradeable contract

### Phase 3: ERC-4337 Contracts (Account Abstraction)

11. **SimpleAccountFactory** - Requires EntryPoint
12. **GoldfirePaymaster** - Requires GoldfireToken, AdminRegistry, EntryPoint

## Step 4: Deploy Contracts

### Option A: Deploy All Contracts (Recommended - Upgradeable)

**Use the new comprehensive deployment script** that properly handles all upgradeable contracts:

```bash
# For Amoy testnet
npm run deploy:all:amoy

# For Polygon mainnet
npm run deploy:all:polygon
```

This script will:
- Deploy all contracts as upgradeable proxies (UUPS pattern)
- Handle dependencies automatically
- Initialize contracts with proper parameters
- Set up authorizations (e.g., HouseMembership authorized to mint tokens)
- Create initial achievements and badges
- Save all addresses to `deployment.json`

### Option B: Legacy Deployment Script

The original `deploy.js` script (for reference, but not recommended for upgradeable contracts):

```bash
# For Amoy testnet
npm run deploy:amoy

# For Polygon mainnet
npm run deploy:polygon
```

**Note**: This script deploys contracts as regular (non-upgradeable) contracts. Use `deploy-all-upgradeable.js` instead.

### Option B: Deploy Individually (For Upgradeable Contracts)

For upgradeable contracts, use the OpenZeppelin upgrades plugin:

#### 4.1 Deploy GoldfireToken

```bash
npm run deploy:goldfire-token:amoy
```

#### 4.2 Deploy AdminRegistry

```bash
npm run deploy:admin-registry:amoy
```

#### 4.3 Deploy AvatarRegistry (Upgradeable)

```bash
npm run deploy:avatar-registry:amoy
```

#### 4.4 Deploy ERC-4337 Contracts

```bash
# Deploy Account Factory
npm run deploy:account-factory:amoy

# Deploy Paymaster
npm run deploy:paymaster:amoy

# Setup ERC-4337 (fund paymaster, configure)
npm run setup:erc4337:amoy
```

### Manual Deployment for Upgradeable Contracts

For contracts that need to be deployed as upgradeable proxies, use this pattern:

```javascript
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  // Deploy as upgradeable proxy
  const Contract = await ethers.getContractFactory("ContractName");
  const contract = await upgrades.deployProxy(
    Contract,
    [/* initialize parameters */],
    { 
      initializer: "initialize",
      kind: "uups"
    }
  );
  
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  console.log("Contract deployed to:", address);
}
```

## Step 5: Post-Deployment Setup

### 5.1 Initialize Contracts

After deployment, you need to initialize upgradeable contracts:

```javascript
// Example: Initialize HouseMembership
const houseMembership = await ethers.getContractAt("HouseMembership", houseMembershipAddress);
await houseMembership.initialize(
  goldfireTokenAddress,
  eventProducerAddress,
  eventListingsAddress
);
```

### 5.2 Authorize Contracts

Some contracts need to authorize others:

```javascript
// Authorize HouseMembership to mint Goldfire tokens
const goldfireToken = await ethers.getContractAt("GoldfireToken", goldfireTokenAddress);
await goldfireToken.setAuthorizedMinter(houseMembershipAddress, true);

// Authorize Ticketing contract in EventListings
const eventListings = await ethers.getContractAt("EventListings", eventListingsAddress);
await eventListings.setAuthorizedContract(ticketingAddress, true);
```

### 5.3 Add Initial Admin

```javascript
const adminRegistry = await ethers.getContractAt("AdminRegistry", adminRegistryAddress);
await adminRegistry.addAdmin(deployerAddress);
```

### 5.4 Setup Paymaster for Gasless Avatar Creation

Enable gasless avatar creation by configuring the paymaster:

```bash
# Run the setup script
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

Or manually:

```javascript
const paymaster = await ethers.getContractAt("GoldfirePaymaster", paymasterAddress);

// Enable avatar creation sponsorship
await paymaster.setSponsorAvatarCreation(true);

// Set avatar registry address
await paymaster.setAvatarRegistry(avatarRegistryAddress);

// Fund the paymaster (optional but recommended)
await paymaster.deposit({ value: ethers.parseEther("0.1") });
```

**Note**: Make sure your `.env` file has:
```
PAYMASTER_ADDRESS=0x...
AVATAR_REGISTRY_ADDRESS=0x...
PAYMASTER_FUND_AMOUNT=0.1
```

## Step 6: Verify Contracts

```bash
# Verify on Amoy
npm run verify:amoy

# Verify on Polygon mainnet
npm run verify:polygon
```

Or verify individually:

```bash
npx hardhat verify --network amoy <CONTRACT_ADDRESS> [CONSTRUCTOR_ARGS]
```

## Step 7: Update Flutter App

Update `lib/constants/app_constants.dart` with deployed addresses:

```dart
// Smart Contract Addresses
static const String powerVerificationContractAddress = '0x...';
static const String houseMembershipContractAddress = '0x...';
static const String activityScriptsContractAddress = '0x...';
static const String eventProducerContractAddress = '0x...';
static const String eventListingsContractAddress = '0x...';
static const String ticketingContractAddress = '0x...';
static const String goldfireTokenContractAddress = '0x...';
static const String adminRegistryContractAddress = '0x...';
static const String accountFactoryContractAddress = '0x...';
static const String paymasterContractAddress = '0x...';
static const String entryPointAddress = '0x...';
```

## Deployment Checklist

- [ ] Environment variables configured
- [ ] Contracts compiled successfully
- [ ] Sufficient MATIC for gas fees
- [ ] GoldfireToken deployed
- [ ] AdminRegistry deployed
- [ ] EventProducer deployed
- [ ] EventListings deployed (with EventProducer)
- [ ] Ticketing deployed (with EventListings, EventProducer)
- [ ] HouseMembership deployed (with GoldfireToken, EventProducer, EventListings)
- [ ] HouseMembership initialized
- [ ] GoldfireToken authorized HouseMembership as minter
- [ ] SimpleAccountFactory deployed (ERC-4337)
- [ ] GoldfirePaymaster deployed (ERC-4337)
- [ ] Paymaster sponsorship enabled
- [ ] Paymaster funded with MATIC
- [ ] Contracts verified on Polygonscan
- [ ] Flutter app updated with addresses
- [ ] Bundler configured (see BUNDLER_SETUP_GUIDE.md)

## Important Notes

### Upgradeable Contracts

Most contracts are now upgradeable using UUPS pattern:
- PowerVerification
- HouseMembership
- ActivityScripts
- EventProducer
- EventListings
- Ticketing
- GoldfireToken
- GoldfirePaymaster
- AdminRegistry
- SimpleAccountFactory
- AvatarRegistry

**Non-upgradeable:**
- SuperstarAvatarRegistry

### Contract Dependencies

- **HouseMembership** requires:
  - GoldfireToken (for token rewards)
  - EventProducer (to verify producers)
  - EventListings (to verify events)

- **EventListings** requires:
  - EventProducer

- **Ticketing** requires:
  - EventListings
  - EventProducer

- **GoldfirePaymaster** requires:
  - GoldfireToken
  - AdminRegistry
  - EntryPoint

## Troubleshooting

### "Insufficient funds"
- Get more MATIC from faucet
- Check wallet balance

### "Contract already initialized"
- Upgradeable contracts can only be initialized once
- Use upgrade script to update implementation

### "Unauthorized" errors
- Make sure contracts are authorized (e.g., HouseMembership authorized to mint tokens)
- Check admin permissions

### Deployment fails
- Check private key format (no 0x prefix)
- Verify RPC URL is accessible
- Ensure sufficient gas

## Next Steps

1. Test all contract functions on testnet
2. Update Flutter app with contract addresses
3. Test end-to-end flows
4. Consider security audit before mainnet
5. Deploy to Polygon mainnet when ready

