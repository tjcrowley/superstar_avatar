# Superstar Avatar Deployment Guide

This guide covers the complete deployment process for the Superstar Avatar platform, including smart contracts and the Flutter mobile application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Smart Contract Deployment](#smart-contract-deployment)
3. [Flutter App Configuration](#flutter-app-configuration)
4. [Testing](#testing)
5. [Production Deployment](#production-deployment)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- Node.js (v16 or higher)
- npm or yarn
- Flutter SDK (3.0 or higher)
- Git
- A code editor (VS Code recommended)

### Required Accounts
- Polygon wallet with MATIC for gas fees
- Polygonscan account for contract verification
- GitHub account for code repository

### Required Knowledge
- Basic understanding of blockchain and smart contracts
- Familiarity with Flutter development
- Understanding of Polygon network

## Smart Contract Deployment

### 1. Setup Smart Contracts

```bash
# Navigate to contracts directory
cd contracts

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

### 2. Configure Environment Variables

Edit the `.env` file in the `contracts` directory:

```env
# Private key of the deployment wallet (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# RPC URLs
POLYGON_RPC_URL=https://polygon-rpc.com
AMOY_RPC_URL=https://rpc-amoy.polygon.technology

# API Keys
POLYGONSCAN_API_KEY=your_polygonscan_api_key
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key

# Optional: Gas reporting
REPORT_GAS=true
```

### 3. Compile Contracts

```bash
# Compile all contracts
npm run compile
```

### 4. Deploy to Testnet (Amoy)

```bash
# Deploy to Amoy testnet
npm run deploy:amoy
```

This will:
- Deploy all four smart contracts
- Create initial achievements and badges
- Set up sample activity scripts
- Authorize the deployer as a verifier
- Save deployment addresses to `deployment.json`

### 5. Verify Contracts on Polygonscan

```bash
# Verify contracts on Amoy testnet
npm run verify:amoy
```

### 6. Deploy to Mainnet (Polygon)

**⚠️ Important**: Only deploy to mainnet after thorough testing on testnet.

```bash
# Deploy to Polygon mainnet
npm run deploy:polygon

# Verify contracts on mainnet
npm run verify:polygon
```

### 7. Update Contract Addresses

After deployment, update the contract addresses in your Flutter app:

```dart
// lib/constants/app_constants.dart
static const String powerVerificationContractAddress = '0x...'; // Actual address
static const String houseMembershipContractAddress = '0x...'; // Actual address
static const String activityScriptsContractAddress = '0x...'; // Actual address
static const String superstarAvatarRegistryContractAddress = '0x...'; // Actual address
```

## Flutter App Configuration

### 1. Setup Flutter Environment

```bash
# Navigate to project root
cd superstar_avatar

# Get dependencies
flutter pub get

# Check for any issues
flutter doctor
```

### 2. Configure App Constants

Update `lib/constants/app_constants.dart` with your deployment information:

```dart
// Blockchain Configuration
static const String polygonRpcUrl = 'https://polygon-rpc.com';
static const String polygonChainId = '137'; // Use '80002' for Amoy testnet

// Smart Contract Addresses (from deployment)
static const String powerVerificationContractAddress = '0x...';
static const String houseMembershipContractAddress = '0x...';
static const String activityScriptsContractAddress = '0x...';
static const String superstarAvatarRegistryContractAddress = '0x...';
```

### 3. Build for Different Platforms

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release
```

#### Web
```bash
# Build for web
flutter build web --release
```

### 4. Platform-Specific Configuration

#### Android Configuration

Update `android/app/build.gradle`:

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

#### iOS Configuration

Update `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>Superstar Avatar</string>
<key>CFBundleIdentifier</key>
<string>com.superstaravatar.app</string>
```

## Testing

### 1. Smart Contract Testing

```bash
# Run all tests
cd contracts
npm test

# Run with coverage
npm run coverage
```

### 2. Flutter App Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run widget tests
flutter test test/widget_test.dart
```

### 3. End-to-End Testing

1. Deploy contracts to testnet
2. Update Flutter app with testnet addresses
3. Test complete user flows:
   - Wallet creation/import
   - Avatar creation
   - Power verification
   - House joining
   - Activity completion
   - Superstar Avatar achievement

## Production Deployment

### 1. Smart Contracts

1. **Final Testing**: Ensure all tests pass on testnet
2. **Security Audit**: Consider professional security audit
3. **Mainnet Deployment**: Deploy to Polygon mainnet
4. **Contract Verification**: Verify on Polygonscan
5. **Documentation**: Update deployment addresses

### 2. Flutter App

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

### 3. Infrastructure Setup

1. **Backend Services** (if needed):
   - Set up API servers
   - Configure databases
   - Set up monitoring

2. **Analytics and Monitoring**:
   - Configure crash reporting (Firebase Crashlytics)
   - Set up analytics (Firebase Analytics)
   - Monitor blockchain transactions

## Troubleshooting

### Common Smart Contract Issues

1. **Deployment Fails**:
   - Check private key format
   - Ensure sufficient MATIC for gas
   - Verify RPC URL is accessible

2. **Contract Verification Fails**:
   - Ensure contract source matches deployed bytecode
   - Check constructor arguments
   - Verify compiler settings

3. **High Gas Costs**:
   - Optimize contract code
   - Use gas-efficient patterns
   - Consider batch operations

### Common Flutter Issues

1. **Build Failures**:
   - Check Flutter version compatibility
   - Update dependencies
   - Clear build cache: `flutter clean`

2. **Blockchain Connection Issues**:
   - Verify RPC URL accessibility
   - Check network configuration
   - Ensure contract addresses are correct

3. **App Store Rejection**:
   - Follow platform guidelines
   - Test on physical devices
   - Address review feedback

### Performance Optimization

1. **Smart Contracts**:
   - Use efficient data structures
   - Minimize storage operations
   - Implement pagination for large datasets

2. **Flutter App**:
   - Optimize images and assets
   - Implement lazy loading
   - Use efficient state management

## Security Considerations

### Smart Contract Security

1. **Access Control**: Ensure proper owner permissions
2. **Input Validation**: Validate all user inputs
3. **Reentrancy Protection**: Use ReentrancyGuard
4. **Emergency Functions**: Include emergency stops
5. **Upgradeability**: Consider upgradeable contracts

### App Security

1. **Private Key Management**: Secure wallet storage
2. **Network Security**: Use HTTPS for all API calls
3. **Input Validation**: Validate all user inputs
4. **Code Obfuscation**: Obfuscate production builds

## Monitoring and Maintenance

### Smart Contract Monitoring

1. **Transaction Monitoring**: Monitor for failed transactions
2. **Event Logging**: Track important events
3. **Gas Usage**: Monitor gas consumption
4. **Security Alerts**: Set up security monitoring

### App Monitoring

1. **Crash Reporting**: Monitor app crashes
2. **Performance Metrics**: Track app performance
3. **User Analytics**: Monitor user behavior
4. **Error Tracking**: Track and resolve errors

## Support and Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Hardhat Documentation](https://hardhat.org/docs)
- [Polygon Documentation](https://docs.polygon.technology/)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Polygon Community](https://polygon.technology/community)
- [GitHub Issues](https://github.com/your-repo/issues)

### Tools
- [Polygonscan](https://polygonscan.com/) - Blockchain explorer
- [Hardhat](https://hardhat.org/) - Development framework
- [Flutter Inspector](https://flutter.dev/docs/development/tools/flutter-inspector) - Debug tool

---

**Note**: This deployment guide should be updated as the project evolves. Always test thoroughly before deploying to production. 