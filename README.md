# SUPERSTAR AVATAR

A decentralized social reputation mobile app for developing social aptitudes through gamification. Built with Flutter and integrated with the Polygon blockchain. **Now featuring gasless avatar creation via ERC-4337 account abstraction!** **Now featuring gasless avatar creation via ERC-4337 account abstraction!**

## 🌟 Overview

SUPERSTAR AVATAR is a gameful social layer that enhances social experiences through the development of five key social aptitudes: **Courage**, **Creativity**, **Connection**, **Insight**, and **Kindness**. It transforms social interactions into meaningful growth opportunities by gamifying personal development and community building.

## ✨ Key Features

### 🎯 Core Powers System
- **Courage**: Face fears and take bold actions in social situations
- **Creativity**: Think outside the box and bring innovative ideas to life
- **Connection**: Build meaningful relationships and foster community
- **Insight**: Understand others deeply and see patterns in social dynamics
- **Kindness**: Show compassion and support others in their journey

### 🏠 House System
- Join houses with like-minded individuals
- Support group accountability and progression
- Community-driven growth and collaboration

### 📱 Mobile App Features
- **Identity Integration**: Create or import Polygon identities
- **Avatar Creation**: Personalized profiles with progress tracking
- **Activity System**: Complete social challenges to earn experience
- **Progress Tracking**: Visual progress bars and level indicators
- **Blockchain Verification**: Decentralized verification of social acts

### 🔗 Blockchain Integration
- **Polygon Network**: Fast, low-cost transactions
- **Smart Contracts**: Power verification, house membership, activity scripts
- **ERC-4337 Account Abstraction**: Gasless transactions via paymaster
- **Gasless Avatar Creation**: Users can create avatars without MATIC
- **Decentralized Storage**: IPFS/Arweave for data storage
- **Zero-Knowledge Proofs**: Privacy-preserving verification

## 🏗️ Architecture

### Frontend (Flutter)
- **State Management**: Riverpod for reactive state management
- **UI Framework**: Material Design 3 with custom theming
- **Navigation**: Bottom navigation with tab-based interface
- **Local Storage**: SharedPreferences and Hive for data persistence

### Backend (Blockchain)
- **Network**: Polygon (MATIC) blockchain
- **Smart Contracts**: Solidity contracts for core functionality
- **Storage**: IPFS/Arweave for decentralized data storage
- **Identity**: Decentralized Identity (DID) standards

### Key Components
```
lib/
├── models/           # Data models
│   ├── avatar.dart   # User avatar model
│   ├── power.dart    # Power system model
│   ├── house.dart    # House community model
│   └── activity_script.dart # Activity challenges
├── providers/        # State management
│   └── avatar_provider.dart # Avatar state provider
├── services/         # Business logic
│   └── blockchain_service.dart # Blockchain integration
├── screens/          # UI screens
│   ├── wallet_setup_screen.dart
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   └── activities_screen.dart
├── widgets/          # Reusable UI components
│   ├── gradient_button.dart
│   ├── power_card.dart
│   └── avatar_profile_card.dart
└── constants/        # App constants and configuration
    └── app_constants.dart
```

## 🚀 Getting Started

### Quick Start

For a complete setup guide, see **[SETUP_GUIDE.md](SETUP_GUIDE.md)** which covers:
- Prerequisites and installation
- Smart contract deployment
- Flutter application setup
- **Gasless transactions setup** (ERC-4337 bundler)
- Configuration
- Running the application
- Testing
- Troubleshooting

**New Feature**: Avatar creation is now **gasless**! See **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** for a 5-minute setup guide.

### Quick Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/superstar_avatar.git
   cd superstar_avatar
   ```

2. **Setup Smart Contracts**
   ```bash
   cd contracts
   npm install
   # Create .env file with PRIVATE_KEY and RPC URLs
   npm run compile
   npm run deploy:all:amoy  # For testnet
   ```

3. **Setup Flutter App**
   ```bash
   cd ..
   flutter pub get
   # Update contract addresses in lib/constants/app_constants.dart
   flutter run
   ```

### Prerequisites
- Flutter SDK (3.6.2 or higher)
- Node.js (v16 or higher)
- Android Studio / VS Code
- Android/iOS device or emulator
- Polygon wallet with MATIC for gas fees

### Configuration

1. **Blockchain Setup**
   - Deploy contracts (see [CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md))
   - Update smart contract addresses in `lib/constants/app_constants.dart`
   - Configure Polygon RPC URL for your environment

2. **Gasless Transactions Setup** (Optional but Recommended)
   - Set up bundler for ERC-4337 (see [BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md))
   - Enable paymaster sponsorship (see [QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md))
   - Configure bundler RPC URL in `lib/constants/app_constants.dart`

3. **Environment Variables**
   - Create `.env` file in `contracts/` directory
   - Add `PRIVATE_KEY`, `RPC_URL`, `POLYGONSCAN_API_KEY`, and `BUNDLER_RPC_URL`

## 📱 App Flow

### 1. Identity Setup
- Create new identity or import existing one
- Secure mnemonic phrase generation
- Polygon network connection

### 2. Avatar Creation (Gasless!)
- Choose avatar name and bio
- Learn about the five powers
- Complete onboarding process
- **No MATIC required** - Avatar creation is sponsored by the paymaster

### 3. Power Development
- Complete activities to earn experience
- Level up powers through social interactions
- Track progress with visual indicators

### 4. Community Engagement
- Join houses for group activities
- Participate in community challenges
- Support other avatars' growth

### 5. Superstar Achievement
- Max out all five powers (Level 10)
- Achieve Superstar Avatar status
- Create and share activity scripts

## 🔧 Development

### Project Structure
```
superstar_avatar/
├── android/          # Android-specific code
├── ios/             # iOS-specific code
├── lib/             # Main Flutter code
├── assets/          # Images, fonts, animations
├── test/            # Unit and widget tests
└── pubspec.yaml     # Dependencies and configuration
```

### Key Dependencies
- **flutter_riverpod**: State management
- **web3dart**: Blockchain integration
- **shared_preferences**: Local storage
- **google_fonts**: Typography
- **flutter_svg**: Vector graphics
- **qr_flutter**: QR code generation
- **mobile_scanner**: QR code scanning

### Testing
```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 🔐 Security Features

- **Identity Security**: BIP39 mnemonic phrase generation
- **Private Key Management**: Secure local storage
- **Transaction Signing**: Cryptographic signature verification
- **Data Privacy**: Zero-knowledge proofs for verification
- **Decentralized Identity**: Self-sovereign identity management

## 🌐 Blockchain Integration

### Smart Contracts
- **PowerVerification**: Tracks power progression and verification
- **HouseMembership**: Manages house enrollment and membership
- **ActivityScript**: Stores and verifies activity scripts
- **GoldfirePaymaster**: ERC-4337 paymaster for gasless transactions
- **SimpleAccountFactory**: ERC-4337 account factory for smart contract wallets
- **GoldfireToken**: ERC-20 token for rewards and gas payments

### Network Configuration
- **Mainnet**: Polygon mainnet for production
- **Testnet**: Amoy testnet for development (replacement for deprecated Mumbai)
- **Local**: Hardhat/Ganache for testing

## 📊 Analytics & Monitoring

- **User Progress**: Track power development and achievements
- **Community Metrics**: House participation and engagement
- **Activity Performance**: Completion rates and feedback
- **Blockchain Metrics**: Transaction success rates and gas usage

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Write comprehensive tests
- Update documentation
- Use conventional commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Polygon team for blockchain infrastructure
- Community contributors and beta testers
- Open source projects that made this possible

## 📞 Support

- **Documentation**: [Wiki](https://github.com/your-username/superstar_avatar/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-username/superstar_avatar/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/superstar_avatar/discussions)
- **Email**: support@superstaravatar.com

## 🔮 Roadmap

### Phase 1: Core Features ✅
- [x] Identity integration
- [x] Avatar creation
- [x] Power system
- [x] Basic activities
- [x] Gasless avatar creation (ERC-4337)
- [x] Paymaster integration

### Phase 2: Community Features 🚧
- [ ] House system implementation
- [ ] Peer verification
- [ ] Community challenges
- [ ] Social features

### Phase 3: Advanced Features 📋
- [ ] Kiosk mode for events
- [ ] Activity script creation
- [ ] Advanced analytics
- [ ] Cross-platform integration

### Phase 4: Scale & Optimize 📋
- [ ] Layer 2 scaling
- [ ] Performance optimization
- [ ] Advanced privacy features
- [ ] Enterprise features

---

**Transform your social experiences into superpowers with SUPERSTAR AVATAR!** 🌟
