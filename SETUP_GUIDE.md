# Superstar Avatar - Complete Setup Guide

This guide will walk you through setting up and running the Superstar Avatar application from scratch, including both the smart contracts and the Flutter mobile application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Structure](#project-structure)
3. [Smart Contract Setup](#smart-contract-setup)
4. [Flutter Application Setup](#flutter-application-setup)
5. [Configuration](#configuration)
6. [Running the Application](#running-the-application)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)
9. [Production Deployment](#production-deployment)

---

## Prerequisites

### Required Software

- **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
- **npm** (comes with Node.js) or **yarn**
- **Flutter SDK** (3.0 or higher) - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Git** - [Download](https://git-scm.com/)
- **Code Editor** (VS Code recommended) - [Download](https://code.visualstudio.com/)
- **Android Studio** (for Android development) - [Download](https://developer.android.com/studio)
- **Xcode** (for iOS development, macOS only) - [Download](https://developer.apple.com/xcode/)

### Required Accounts

- **Polygon Wallet** with MATIC for gas fees
- **Polygonscan Account** (optional, for contract verification) - [Sign Up](https://polygonscan.com/register)
- **Alchemy/Infura Account** (optional, for better RPC performance) - [Alchemy](https://www.alchemy.com/) | [Infura](https://infura.io/)

### Required Knowledge

- Basic understanding of blockchain and smart contracts
- Familiarity with Flutter/Dart development
- Understanding of Polygon network

---

## Project Structure

```
superstar_avatar/
├── contracts/              # Smart contracts (Solidity)
│   ├── scripts/           # Deployment scripts
│   ├── src/               # Contract source files
│   ├── test/              # Contract tests
│   └── hardhat.config.js  # Hardhat configuration
│
├── lib/                   # Flutter application source
│   ├── constants/        # App constants
│   ├── models/           # Data models
│   ├── providers/        # State management (Riverpod)
│   ├── screens/          # UI screens
│   ├── services/         # Business logic services
│   └── widgets/          # Reusable widgets
│
├── android/              # Android-specific files
├── ios/                  # iOS-specific files
├── macos/                # macOS-specific files
└── pubspec.yaml          # Flutter dependencies
```

---

## Smart Contract Setup

### Step 1: Navigate to Contracts Directory

```bash
cd contracts
```

### Step 2: Install Dependencies

```bash
npm install
```

This installs:
- Hardhat and plugins
- OpenZeppelin contracts
- Ethers.js
- Other required dependencies

### Step 3: Create Environment File

Create a `.env` file in the `contracts` directory:

```bash
touch .env
```

Add the following content:

```env
# Private key of deployment wallet (without 0x prefix)
# ⚠️ SECURITY: Never commit this file to git!
PRIVATE_KEY=your_private_key_here

# RPC URLs
POLYGON_RPC_URL=https://polygon-rpc.com
AMOY_RPC_URL=https://rpc-amoy.polygon.technology

# Optional: Custom RPC URLs (recommended for better performance)
# Get from Alchemy, Infura, or QuickNode
# AMOY_RPC_URL=https://polygon-amoy.g.alchemy.com/v2/YOUR_API_KEY

# API Keys (optional but recommended)
POLYGONSCAN_API_KEY=your_polygonscan_api_key
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key

# ERC-4337 EntryPoint (for Account Abstraction)
# Mainnet: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
# Amoy: Check Polygon documentation for testnet EntryPoint
ENTRY_POINT_ADDRESS=0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789

# Optional: Initial paymaster funding (in MATIC)
PAYMASTER_INITIAL_FUNDING=0.1

# Bundler Configuration (for gasless transactions)
# Get API key from Pimlico, Stackup, or Alchemy
# Pimlico: https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY
# Stackup: https://api.stackup.sh/v1/node/YOUR_API_KEY
# Alchemy: https://polygon-amoy.g.alchemy.com/v2/YOUR_API_KEY
BUNDLER_RPC_URL=https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY

# Paymaster and Avatar Registry addresses (for setup script)
PAYMASTER_ADDRESS=0x...
AVATAR_REGISTRY_ADDRESS=0x...
PAYMASTER_FUND_AMOUNT=0.1
```

### Step 4: Get Testnet MATIC (for Amoy Testnet)

If deploying to testnet, get free MATIC from:

1. **Polygon Faucet**: https://faucet.polygon.technology/
   - Select "Amoy" network
   - Enter your wallet address
   - Request testnet MATIC

2. **Alchemy Faucet**: https://www.alchemy.com/faucets/polygon-amoy

3. **QuickNode Faucet**: https://faucet.quicknode.com/polygon/amoy

**Note**: You'll need at least 0.5 MATIC for all contract deployments.

### Step 5: Compile Contracts

```bash
npm run compile
```

This compiles all Solidity contracts and checks for errors. Fix any compilation errors before proceeding.

### Step 6: Deploy Contracts

#### Option A: Deploy All Contracts (Recommended)

Deploys all contracts as upgradeable proxies with proper initialization:

```bash
# For Amoy testnet
npm run deploy:all:amoy

# For Polygon mainnet (⚠️ Only after thorough testing)
npm run deploy:all:polygon
```

This script will:
- Deploy all 12 contracts in the correct order
- Handle dependencies automatically
- Initialize upgradeable contracts
- Set up authorizations (e.g., HouseMembership can mint tokens)
- Create initial achievements and badges
- Save addresses to `deployment.json`

#### Option B: Deploy Individual Contracts

If you need to deploy contracts individually:

```bash
# Deploy GoldfireToken
npm run deploy:goldfire-token:amoy

# Deploy AdminRegistry
npm run deploy:admin-registry:amoy

# Deploy AvatarRegistry
npm run deploy:avatar-registry:amoy

# Deploy Account Factory (ERC-4337)
npm run deploy:account-factory:amoy

# Deploy Paymaster (ERC-4337)
npm run deploy:paymaster:amoy

# Setup ERC-4337
npm run setup:erc4337:amoy
```

### Step 7: Verify Contracts (Optional)

Verify contracts on Polygonscan for transparency:

```bash
# Verify on Amoy
npm run verify:amoy

# Verify on Polygon mainnet
npm run verify:polygon
```

### Step 8: Save Deployment Information

After deployment, the script saves all addresses to `contracts/deployment.json`. You'll need these addresses for the Flutter app configuration.

---

## Flutter Application Setup

### Step 1: Navigate to Project Root

```bash
cd ..  # If you're in the contracts directory
# or
cd /path/to/superstar_avatar
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

This installs all Flutter packages defined in `pubspec.yaml`.

### Step 3: Check Flutter Setup

```bash
flutter doctor
```

Fix any issues reported by Flutter doctor before proceeding.

### Step 4: Configure Contract Addresses

Open `lib/constants/app_constants.dart` and update the contract addresses with values from `contracts/deployment.json`:

```dart
// Smart Contract Addresses (from deployment.json)
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

### Step 5: Configure Network Settings

In the same file, update network configuration:

```dart
// For Amoy Testnet
static const String polygonRpcUrl = 'https://rpc-amoy.polygon.technology';
static const String polygonChainId = '80002';
static const String polygonExplorerUrl = 'https://amoy.polygonscan.com';

// For Polygon Mainnet
// static const String polygonRpcUrl = 'https://polygon-rpc.com';
// static const String polygonChainId = '137';
// static const String polygonExplorerUrl = 'https://polygonscan.com';
```

### Step 5.5: Configure Bundler for Gasless Transactions (Optional but Recommended)

To enable gasless avatar creation, you need to set up a bundler:

1. **Get a Bundler API Key** (recommended: Pimlico)
   - Sign up at [https://pimlico.io](https://pimlico.io)
   - Get your API key from the dashboard

2. **Set Bundler URL** in `lib/constants/app_constants.dart`:

```dart
// Bundler Configuration
static const String bundlerRpcUrl = 'https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY';
```

Or use environment variable:
```bash
export BUNDLER_RPC_URL="https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY"
```

3. **Enable Paymaster Sponsorship**:

```bash
cd contracts
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

Make sure your `.env` file has:
```
PAYMASTER_ADDRESS=0x...
AVATAR_REGISTRY_ADDRESS=0x...
PAYMASTER_FUND_AMOUNT=0.1  # Optional: fund with 0.1 MATIC
```

For detailed bundler setup, see:
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Quick 5-minute setup
- **[BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md)** - Comprehensive guide with all options

### Step 6: Platform-Specific Setup

#### Android Setup

1. **Update `android/app/build.gradle`**:

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        applicationId "com.superstaravatar.app"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

2. **Update `android/app/src/main/AndroidManifest.xml`** (if needed):

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- Add other permissions as needed -->
</manifest>
```

#### iOS Setup (macOS only)

1. **Update `ios/Runner/Info.plist`**:

```xml
<key>CFBundleDisplayName</key>
<string>Superstar Avatar</string>
<key>CFBundleIdentifier</key>
<string>com.superstaravatar.app</string>
```

2. **Install CocoaPods dependencies**:

```bash
cd ios
pod install
cd ..
```

---

## Configuration

### Environment Variables

The Flutter app uses constants defined in `lib/constants/app_constants.dart`. Key configurations:

- **Blockchain Network**: RPC URL and Chain ID
- **Contract Addresses**: All deployed contract addresses
- **API Keys**: (if using external services)
- **Feature Flags**: Enable/disable features

### App Constants

Review and update `lib/constants/app_constants.dart` for:
- Theme colors
- App metadata
- Storage keys
- API endpoints (if any)

---

## Running the Application

### Step 1: Check Connected Devices

```bash
# List connected devices
flutter devices
```

### Step 2: Run the Application

#### Android

```bash
# Run on connected Android device or emulator
flutter run

# Or build APK
flutter build apk --release
```

#### iOS (macOS only)

```bash
# Run on connected iOS device or simulator
flutter run

# Or build for iOS
flutter build ios --release
```

#### Web

```bash
# Run on web browser
flutter run -d chrome

# Or build for web
flutter build web --release
```

### Step 3: First Launch

On first launch, the app will:
1. Show onboarding screen
2. Guide you through wallet creation/import
3. Set up your avatar profile
4. Connect to the blockchain network

---

## Testing

### Smart Contract Tests

```bash
cd contracts

# Run all tests
npm test

# Run with coverage
npm run coverage
```

### Flutter Tests

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run widget tests
flutter test test/widget_test.dart
```

### End-to-End Testing

1. Deploy contracts to testnet
2. Update Flutter app with testnet addresses
3. Test complete user flows:
   - Wallet creation/import
   - Avatar creation
   - Power verification
   - House creation/joining
   - Activity completion
   - Token rewards
   - Event producer registration
   - Admin functions

---

## Troubleshooting

### Common Smart Contract Issues

#### "Insufficient funds" error
- **Solution**: Get more MATIC from faucet
- **Check**: Wallet balance with `npm run balance` (if script exists)

#### "Nonce too high" error
- **Solution**: Wait a few minutes and try again
- **Alternative**: Manually set nonce in Hardhat config

#### "Contract verification failed"
- **Solution**: 
  - Verify Polygonscan API key is correct
  - Wait a few minutes after deployment before verifying
  - Check that constructor arguments match exactly

#### "RPC rate limit exceeded"
- **Solution**: 
  - Use a custom RPC endpoint (Alchemy, Infura, QuickNode)
  - Wait and try again later

#### Contracts not showing on Polygonscan
- **Solution**: 
  - Wait a few minutes for blockchain indexing
  - Verify you're on the correct network (Amoy vs Mainnet)
  - Check transaction hash on Polygonscan

### Common Flutter Issues

#### Build Failures

```bash
# Clean build cache
flutter clean
flutter pub get

# Check Flutter version
flutter --version

# Update dependencies
flutter pub upgrade
```

#### Blockchain Connection Issues

- **Verify RPC URL**: Check if RPC endpoint is accessible
- **Check Network**: Ensure correct chain ID
- **Verify Addresses**: Confirm contract addresses are correct
- **Test Connection**: Try accessing RPC URL in browser

#### App Store Rejection

- **Follow Guidelines**: Review platform-specific guidelines
- **Test on Devices**: Test on physical devices, not just emulators
- **Address Feedback**: Respond to review feedback promptly

#### Package Conflicts

```bash
# Clear pub cache
flutter pub cache repair

# Remove pubspec.lock and reinstall
rm pubspec.lock
flutter pub get
```

### Performance Issues

#### Smart Contracts
- Use efficient data structures
- Minimize storage operations
- Implement pagination for large datasets

#### Flutter App
- Optimize images and assets
- Implement lazy loading
- Use efficient state management
- Profile with `flutter run --profile`

---

## Production Deployment

### Smart Contracts

1. **Final Testing**: Ensure all tests pass on testnet
2. **Security Audit**: Consider professional security audit
3. **Mainnet Deployment**: Deploy to Polygon mainnet
4. **Contract Verification**: Verify on Polygonscan
5. **Documentation**: Update deployment addresses

### Flutter App

1. **App Store Preparation**:
   - Create developer accounts (Google Play, App Store)
   - Prepare app store listings
   - Create app icons and screenshots

2. **Build Production Versions**:
   ```bash
   # Android
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

3. **Submit to Stores**:
   - Upload to Google Play Console
   - Upload to App Store Connect

### Infrastructure

1. **Backend Services** (if needed):
   - Set up API servers
   - Configure databases
   - Set up monitoring

2. **Analytics and Monitoring**:
   - Configure crash reporting (Firebase Crashlytics)
   - Set up analytics (Firebase Analytics)
   - Monitor blockchain transactions

---

## Quick Start Checklist

### Basic Setup
- [ ] Install Node.js and npm
- [ ] Install Flutter SDK
- [ ] Clone repository
- [ ] Install contract dependencies (`cd contracts && npm install`)
- [ ] Create `.env` file with private key
- [ ] Get testnet MATIC from faucet
- [ ] Compile contracts (`npm run compile`)
- [ ] Deploy contracts (`npm run deploy:all:amoy`)
- [ ] Verify contracts (`npm run verify:amoy`)
- [ ] Install Flutter dependencies (`flutter pub get`)
- [ ] Update contract addresses in `app_constants.dart`

### Gasless Transactions (Optional but Recommended)
- [ ] Get bundler API key (Pimlico recommended)
- [ ] Configure bundler URL in `app_constants.dart` or environment variable
- [ ] Enable paymaster sponsorship (`npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy`)
- [ ] Fund paymaster with MATIC (via setup script or manually)

### Testing
- [ ] Run Flutter app (`flutter run`)
- [ ] Test wallet creation
- [ ] Test gasless avatar creation (if bundler configured)
- [ ] Test contract interactions

---

## Additional Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Hardhat Documentation](https://hardhat.org/docs)
- [Polygon Documentation](https://docs.polygon.technology/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Polygon Community](https://polygon.technology/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

### Tools
- [Polygonscan](https://polygonscan.com/) - Blockchain explorer
- [Hardhat](https://hardhat.org/) - Development framework
- [Flutter Inspector](https://flutter.dev/docs/development/tools/flutter-inspector) - Debug tool

---

## Security Reminders

- ⚠️ **Never commit `.env` file to git**
- ⚠️ **Never share your private key**
- ⚠️ **Use a separate wallet for testing**
- ⚠️ **Keep API keys secure**
- ⚠️ **Test thoroughly on testnet before mainnet**
- ⚠️ **Review smart contract code before deployment**
- ⚠️ **Consider security audit for production contracts**

---

## Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review error messages carefully
3. Check contract deployment logs
4. Verify network connectivity
5. Check Flutter doctor output
6. Review contract addresses in `deployment.json`

For additional help, refer to the project's issue tracker or documentation.

---

**Last Updated**: 2024
**Version**: 1.0.0

