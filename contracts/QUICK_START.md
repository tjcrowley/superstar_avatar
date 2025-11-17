# Quick Start: Deploy to Mumbai Testnet

## Prerequisites Checklist

- [ ] Node.js installed (v16+)
- [ ] Wallet with Mumbai testnet MATIC (get from [faucet](https://faucet.polygon.technology/))
- [ ] Polygonscan API key (optional, for verification)

## 5-Minute Setup

### 1. Install Dependencies
```bash
cd contracts
npm install
```

### 2. Set Up Environment
```bash
# Copy the example file
cp .env.example .env

# Edit .env and add:
# - Your private key (without 0x)
# - Mumbai RPC URL (or use default)
# - Polygonscan API key (optional)
```

### 3. Compile Contracts
```bash
npm run compile
```

### 4. Deploy to Mumbai
```bash
npm run deploy:mumbai
```

### 5. Verify Contracts (Optional)
```bash
npm run verify:mumbai
```

## What You'll Get

After deployment, you'll have:
- `deployment.json` with all contract addresses
- All 7 contracts deployed and ready to use
- Initial achievements, badges, and sample activities created

## Update Flutter App

Copy the contract addresses from `deployment.json` to `lib/constants/app_constants.dart`:

```dart
static const String powerVerificationContractAddress = '0x...';
static const String houseMembershipContractAddress = '0x...';
// ... etc
```

Also update:
```dart
static const String polygonRpcUrl = 'https://rpc-mumbai.maticvigil.com';
static const String polygonChainId = '80001'; // Mumbai
```

## Troubleshooting

**"Insufficient funds"** → Get more MATIC from faucet  
**"Nonce too high"** → Wait a few minutes and retry  
**"Verification failed"** → Wait 1-2 minutes after deployment before verifying

## Full Guide

See [MUMBAI_DEPLOYMENT.md](../MUMBAI_DEPLOYMENT.md) for detailed instructions.

