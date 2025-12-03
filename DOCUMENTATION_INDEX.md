# Superstar Avatar - Documentation Index

Complete documentation for the Superstar Avatar project, including setup, deployment, and feature guides.

## 🚀 Getting Started

### New to the Project?
1. Start with **[README.md](README.md)** - Overview and quick start
2. Follow **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup instructions
3. See **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Enable gasless transactions (5 minutes)

### Quick Links
- **[README.md](README.md)** - Project overview and features
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup guide
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Quick bundler setup

## 📚 Core Documentation

### Setup & Installation
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup guide for contracts and Flutter app
- **[CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md)** - Detailed contract deployment instructions
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Quick bundler setup for gasless transactions

### Gasless Transactions & ERC-4337
- **[BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md)** - Comprehensive bundler setup guide
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - 5-minute bundler setup
- **[WALLET_FUNDING_GUIDE.md](WALLET_FUNDING_GUIDE.md)** - Wallet funding options (includes gasless setup)

### Deployment
- **[CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md)** - Smart contract deployment
- **[AMOY_DEPLOYMENT.md](AMOY_DEPLOYMENT.md)** - Amoy testnet deployment
- **[MUMBAI_DEPLOYMENT.md](MUMBAI_DEPLOYMENT.md)** - Mumbai testnet (deprecated, use Amoy)

### Payment & Funding
- **[WALLET_FUNDING_GUIDE.md](WALLET_FUNDING_GUIDE.md)** - Wallet funding and gasless transactions
- **[PAYMENT_INTEGRATION_GUIDE.md](PAYMENT_INTEGRATION_GUIDE.md)** - Stripe payment integration

### Development & Debugging
- **[ANDROID_DEBUG_GUIDE.md](ANDROID_DEBUG_GUIDE.md)** - Android debugging guide
- **[TROUBLESHOOTING_ANDROID.md](TROUBLESHOOTING_ANDROID.md)** - Common Android issues

## 🎯 Feature Guides

### Gasless Avatar Creation
The app now supports **gasless avatar creation** using ERC-4337 account abstraction:

- Users don't need MATIC to create their first avatar
- Automatic sponsorship via paymaster
- Better user experience

**Setup:**
1. See **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** for quick setup
2. Or **[BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md)** for detailed options
3. Run `scripts/setup-paymaster-sponsorship.js` to enable sponsorship

### Smart Contracts
- **PowerVerification** - Tracks power progression
- **HouseMembership** - Manages house enrollment
- **ActivityScripts** - Activity management
- **GoldfirePaymaster** - ERC-4337 paymaster for gasless transactions
- **SimpleAccountFactory** - ERC-4337 account factory
- **GoldfireToken** - ERC-20 token for rewards

## 📖 Documentation by Topic

### Blockchain & Smart Contracts
- **[CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md)** - Deploy all contracts
- **[AMOY_DEPLOYMENT.md](AMOY_DEPLOYMENT.md)** - Amoy testnet specific
- **[contracts/README.md](contracts/README.md)** - Contract development guide

### Mobile App Development
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Flutter app setup
- **[ANDROID_DEBUG_GUIDE.md](ANDROID_DEBUG_GUIDE.md)** - Android debugging
- **[TROUBLESHOOTING_ANDROID.md](TROUBLESHOOTING_ANDROID.md)** - Android troubleshooting

### Account Abstraction & Gasless Transactions
- **[BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md)** - Complete bundler guide
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Quick bundler setup
- **[WALLET_FUNDING_GUIDE.md](WALLET_FUNDING_GUIDE.md)** - Funding options

### Backend & Services
- **[backend/README.md](backend/README.md)** - Backend service documentation
- **[PAYMENT_INTEGRATION_GUIDE.md](PAYMENT_INTEGRATION_GUIDE.md)** - Payment integration

## 🔧 Scripts & Tools

### Deployment Scripts
- `contracts/scripts/deploy-all-upgradeable.js` - Deploy all contracts as upgradeable
- `contracts/scripts/setup-paymaster-sponsorship.js` - Enable gasless avatar creation
- `contracts/scripts/setup-erc4337.js` - Setup ERC-4337 infrastructure

### Debug Scripts
- `debug_android.sh` - Android debugging helper
- `view_app_logs.sh` - View app-specific logs

## 📋 Checklists

### Initial Setup
- [ ] Install prerequisites (Node.js, Flutter, etc.)
- [ ] Clone repository
- [ ] Install dependencies (`npm install`, `flutter pub get`)
- [ ] Configure environment variables
- [ ] Deploy contracts
- [ ] Update Flutter app with contract addresses
- [ ] Set up bundler (for gasless transactions)
- [ ] Enable paymaster sponsorship

### Gasless Transactions Setup
- [ ] Get bundler API key (Pimlico recommended)
- [ ] Configure bundler URL in `app_constants.dart`
- [ ] Deploy paymaster contract
- [ ] Fund paymaster with MATIC
- [ ] Enable avatar creation sponsorship
- [ ] Test gasless avatar creation

## 🆘 Troubleshooting

### Common Issues
- **Android crashes**: See [TROUBLESHOOTING_ANDROID.md](TROUBLESHOOTING_ANDROID.md)
- **Contract deployment errors**: See [CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md)
- **Bundler issues**: See [BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md)
- **Payment issues**: See [PAYMENT_INTEGRATION_GUIDE.md](PAYMENT_INTEGRATION_GUIDE.md)

## 🔗 External Resources

### Polygon Network
- [Polygon Documentation](https://docs.polygon.technology/)
- [Amoy Testnet Faucet](https://faucet.polygon.technology/)
- [Polygonscan (Amoy)](https://amoy.polygonscan.com/)

### ERC-4337 & Account Abstraction
- [ERC-4337 Documentation](https://docs.erc4337.io/)
- [Pimlico Documentation](https://docs.pimlico.io/)
- [Stackup Documentation](https://docs.stackup.sh/)

### Flutter
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)

## 📝 Contributing

When adding new features or updating documentation:

1. Update relevant documentation files
2. Add examples and code snippets
3. Update this index if adding new guides
4. Test all instructions
5. Update checklists if needed

## 📞 Support

- **GitHub Issues**: [Create an issue](https://github.com/your-username/superstar_avatar/issues)
- **Documentation**: Check relevant guide above
- **Discussions**: [GitHub Discussions](https://github.com/your-username/superstar_avatar/discussions)

---

**Last Updated**: 2024
**Version**: 1.0.0

