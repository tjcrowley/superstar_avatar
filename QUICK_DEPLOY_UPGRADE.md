# Quick Deploy & Upgrade Reference

Quick reference for deploying and upgrading contracts for gasless avatar creation.

## 🚀 Quick Start

### First Time Setup (No Contracts Deployed)

```bash
cd contracts

# 1. Deploy all contracts
npm run deploy:all:amoy

# 2. Enable paymaster sponsorship
npm run setup:paymaster:amoy

# 3. Check deployment status
npm run check:deployment:amoy
```

### Upgrading Existing Contracts

```bash
cd contracts

# 1. Check what's deployed
npm run check:deployment:amoy

# 2. Upgrade paymaster (if needed)
npm run upgrade:paymaster:amoy

# 3. Enable paymaster sponsorship
npm run setup:paymaster:amoy

# 4. Verify upgrade
npm run check:deployment:amoy
```

## 📋 Step-by-Step

### Step 1: Check Current Status

```bash
npm run check:deployment:amoy
```

This shows:
- Which contracts are deployed
- Which contracts are missing
- Paymaster configuration status

### Step 2: Deploy or Upgrade

**If GoldfirePaymaster is NOT deployed:**
```bash
npm run deploy:paymaster:amoy
```

**If GoldfirePaymaster IS deployed:**
```bash
npm run upgrade:paymaster:amoy
```

### Step 3: Configure Paymaster

```bash
npm run setup:paymaster:amoy
```

This enables:
- Avatar creation sponsorship
- Sets avatar registry address
- Funds paymaster (if configured in .env)

### Step 4: Update Flutter App

Update `lib/constants/app_constants.dart` with addresses from `contracts/deployment.json`:

```dart
static const String paymasterContractAddress = '0x...'; // From deployment.json
static const String accountFactoryContractAddress = '0x...'; // From deployment.json
static const String bundlerRpcUrl = 'https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY';
```

## 🔧 Available Commands

### Deployment
- `npm run deploy:all:amoy` - Deploy all contracts
- `npm run deploy:paymaster:amoy` - Deploy paymaster only
- `npm run deploy:account-factory:amoy` - Deploy account factory only

### Upgrade
- `npm run upgrade:paymaster:amoy` - Upgrade paymaster
- `npm run upgrade:avatar-registry:amoy` - Upgrade avatar registry

### Setup
- `npm run setup:paymaster:amoy` - Enable paymaster sponsorship
- `npm run setup:erc4337:amoy` - Setup ERC-4337 infrastructure

### Check
- `npm run check:deployment:amoy` - Check deployment status

## ⚙️ Environment Variables

Make sure your `.env` file has:

```env
PRIVATE_KEY=your_private_key
AMOY_RPC_URL=https://rpc-amoy.polygon.technology
ENTRY_POINT_ADDRESS=0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789

# For setup script
PAYMASTER_ADDRESS=0x...  # Auto-filled if using deploy-all
AVATAR_REGISTRY_ADDRESS=0x...  # Auto-filled if using deploy-all
PAYMASTER_FUND_AMOUNT=0.1  # Optional: fund paymaster
```

## 🎯 Common Scenarios

### Scenario 1: Fresh Deployment
```bash
npm run deploy:all:amoy
npm run setup:paymaster:amoy
```

### Scenario 2: Upgrade Existing Paymaster
```bash
npm run upgrade:paymaster:amoy
npm run setup:paymaster:amoy
```

### Scenario 3: Deploy Only Missing Contracts
```bash
npm run check:deployment:amoy  # See what's missing
npm run deploy:paymaster:amoy  # Deploy missing contracts
npm run setup:paymaster:amoy
```

## ✅ Verification Checklist

After deployment/upgrade:

- [ ] Contracts deployed successfully
- [ ] Paymaster upgraded (if needed)
- [ ] Sponsorship enabled
- [ ] Paymaster funded
- [ ] Flutter app updated with addresses
- [ ] Bundler configured
- [ ] Test gasless avatar creation

## 🆘 Troubleshooting

### "Contract not found"
- Check `deployment.json` for contract addresses
- Verify you're on the correct network
- Run `npm run check:deployment:amoy`

### "Upgrade failed"
- Ensure contract is upgradeable (UUPS pattern)
- Check storage layout hasn't changed
- Review error message for details

### "Insufficient funds"
- Get testnet MATIC from faucet
- Check deployer wallet balance
- Reduce PAYMASTER_FUND_AMOUNT if needed

## 📚 Full Documentation

For detailed information, see:
- **[DEPLOYMENT_AND_UPGRADE_GUIDE.md](DEPLOYMENT_AND_UPGRADE_GUIDE.md)** - Complete guide
- **[CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md)** - Full deployment guide
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Bundler setup

---

**Quick Command Summary:**
```bash
# Check status
npm run check:deployment:amoy

# Upgrade paymaster
npm run upgrade:paymaster:amoy

# Enable sponsorship
npm run setup:paymaster:amoy
```

