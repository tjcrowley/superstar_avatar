# Quick Start: Deploy to Amoy Testnet

## Prerequisites Checklist

- [ ] Node.js installed (v16+)
- [ ] Wallet with Amoy testnet MATIC (get from [faucet](https://faucet.polygon.technology/))
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
# - Amoy RPC URL (default: https://rpc-amoy.polygon.technology)
# - Polygonscan API key (optional)
```

### 3. Compile Contracts
```bash
npm run compile
```

### 4. Deploy to Amoy
```bash
npm run deploy:amoy
```

### 5. Verify Contracts (Optional)
```bash
npm run verify:amoy
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
static const String polygonRpcUrl = 'https://rpc-amoy.polygon.technology';
static const String polygonChainId = '80002'; // Amoy
```

## Troubleshooting

**"Insufficient funds"** → Get more MATIC from faucet  
**"Nonce too high"** → Wait a few minutes and retry  
**"Verification failed"** → Wait 1-2 minutes after deployment before verifying

## Full Guide

See [AMOY_DEPLOYMENT.md](../AMOY_DEPLOYMENT.md) for detailed instructions.

