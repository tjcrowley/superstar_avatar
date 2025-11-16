# Superstar Avatar Smart Contracts

This directory contains the smart contracts for the Superstar Avatar decentralized social platform, built on the Polygon blockchain.

## Overview

The Superstar Avatar system consists of four main smart contracts that work together to create a gamified social experience:

1. **PowerVerification** - Manages power progression and verification
2. **HouseMembership** - Handles house creation and membership
3. **ActivityScripts** - Manages activity scripts and their completion
4. **SuperstarAvatarRegistry** - Tracks Superstar Avatars and achievements

## Contract Architecture

### PowerVerification Contract
- **Purpose**: Manages the five social aptitudes (Courage, Creativity, Connection, Insight, Kindness)
- **Key Features**:
  - Power level progression (1-10 levels)
  - Experience tracking and verification
  - Superstar Avatar status detection
  - Verification history and statistics
- **Main Functions**:
  - `verifyPower()` - Award experience to a power
  - `getPowerData()` - Retrieve power information
  - `canBecomeSuperstarAvatar()` - Check Superstar status eligibility

### HouseMembership Contract
- **Purpose**: Manages small communities (houses) within the platform
- **Key Features**:
  - House creation and management
  - Member enrollment and management
  - House activities and completion tracking
  - Leader permissions and house statistics
- **Main Functions**:
  - `createHouse()` - Create a new house
  - `joinHouse()` - Join an existing house
  - `createHouseActivity()` - Create house-specific activities
  - `completeActivity()` - Complete house activities

### ActivityScripts Contract
- **Purpose**: Manages activity scripts and their verification system
- **Key Features**:
  - Activity script creation and management
  - Verification system for activity completion
  - Experience rewards and completion tracking
  - Authorized verifier system
- **Main Functions**:
  - `createActivityScript()` - Create new activity scripts
  - `completeActivity()` - Submit activity completion
  - `verifyActivity()` - Verify activity completion
  - `setVerifierAuthorization()` - Manage verifiers

### SuperstarAvatarRegistry Contract
- **Purpose**: Tracks Superstar Avatars and their achievements
- **Key Features**:
  - Superstar Avatar registration and management
  - Achievement and badge system
  - Progress tracking and statistics
  - Metadata management
- **Main Functions**:
  - `registerSuperstarAvatar()` - Register as Superstar Avatar
  - `unlockAchievement()` - Unlock achievements
  - `awardBadge()` - Award badges
  - `createAchievement()` - Create new achievements

## Setup and Installation

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn
- Hardhat

### Installation

1. **Install dependencies**:
   ```bash
   cd contracts
   npm install
   ```

2. **Environment setup**:
   Create a `.env` file in the contracts directory:
   ```env
   PRIVATE_KEY=your_private_key_here
   POLYGON_RPC_URL=https://polygon-rpc.com
   MUMBAI_RPC_URL=https://rpc-mumbai.maticvigil.com
   POLYGONSCAN_API_KEY=your_polygonscan_api_key
   COINMARKETCAP_API_KEY=your_coinmarketcap_api_key
   ```

3. **Compile contracts**:
   ```bash
   npm run compile
   ```

## Deployment

### Local Development
```bash
# Start local Hardhat node
npm run node

# Deploy to local network
npm run deploy:local
```

### Testnet (Mumbai)
```bash
# Deploy to Mumbai testnet
npm run deploy:mumbai
```

### Mainnet (Polygon)
```bash
# Deploy to Polygon mainnet
npm run deploy:polygon
```

### Contract Verification
After deployment, verify your contracts on Polygonscan:

```bash
# For Mumbai testnet
npm run verify:mumbai

# For Polygon mainnet
npm run verify:polygon
```

## Testing

Run the test suite:
```bash
npm test
```

Run with coverage:
```bash
npm run coverage
```

## Integration with Flutter App

### Contract Addresses
After deployment, update your Flutter app's `blockchain_service.dart` with the deployed contract addresses:

```dart
class BlockchainService {
  // Contract addresses (update these after deployment)
  static const String powerVerificationAddress = "0x...";
  static const String houseMembershipAddress = "0x...";
  static const String activityScriptsAddress = "0x...";
  static const String superstarAvatarRegistryAddress = "0x...";
}
```

### Contract ABIs
The contract ABIs will be generated in the `artifacts/` directory after compilation. Copy these to your Flutter app's assets or include them directly in your code.

### Key Integration Points

1. **Power Verification**:
   ```dart
   // Verify a power
   await powerVerificationContract.verifyPower(
     avatarId,
     powerType,
     experience,
     metadata,
   );
   ```

2. **House Management**:
   ```dart
   // Join a house
   await houseMembershipContract.joinHouse(
     houseId,
     avatarId,
     avatarName,
   );
   ```

3. **Activity Completion**:
   ```dart
   // Complete an activity
   await activityScriptsContract.completeActivity(
     activityId,
     avatarId,
     proof,
   );
   ```

4. **Superstar Avatar Registration**:
   ```dart
   // Register as Superstar Avatar
   await superstarAvatarRegistryContract.registerSuperstarAvatar(
     avatarId,
     name,
     bio,
     powerLevels,
     powerExperience,
     totalExperience,
   );
   ```

## Gas Optimization

The contracts are optimized for gas efficiency:
- Uses Solidity 0.8.19 with optimizer enabled
- Efficient data structures and mappings
- Batch operations where possible
- Minimal storage operations

## Security Features

- **Access Control**: Owner-only functions for critical operations
- **Input Validation**: Comprehensive parameter validation
- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard
- **Emergency Functions**: Owner can reset data if needed
- **Verification System**: Multi-step verification for critical actions

## Events and Monitoring

Each contract emits events for important actions:
- `PowerVerified` - When a power is verified
- `LevelUp` - When an avatar levels up
- `SuperstarAvatarAchieved` - When Superstar status is achieved
- `HouseCreated` - When a house is created
- `MemberJoined` - When someone joins a house
- `ActivityCompleted` - When an activity is completed
- `AchievementUnlocked` - When an achievement is unlocked

## Development Guidelines

### Adding New Features
1. Create a new branch for your feature
2. Write tests for new functionality
3. Update documentation
4. Submit a pull request

### Code Style
- Follow Solidity style guide
- Use meaningful variable names
- Add comprehensive comments
- Include NatSpec documentation

### Testing
- Write unit tests for all functions
- Test edge cases and error conditions
- Use integration tests for complex workflows
- Maintain high test coverage

## Troubleshooting

### Common Issues

1. **Compilation Errors**:
   - Ensure all dependencies are installed
   - Check Solidity version compatibility
   - Verify import paths

2. **Deployment Failures**:
   - Check network configuration
   - Verify private key and RPC URL
   - Ensure sufficient gas and MATIC

3. **Integration Issues**:
   - Verify contract addresses are correct
   - Check ABI compatibility
   - Ensure proper network configuration

### Support
For issues and questions:
- Check the test files for usage examples
- Review the contract comments and documentation
- Open an issue in the repository

## License

This project is licensed under the MIT License - see the LICENSE file for details. 