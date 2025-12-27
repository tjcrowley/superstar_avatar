# Deployment and Upgrade Guide - Gasless Avatar Creation

This guide covers deploying new contracts and upgrading existing contracts to enable gasless avatar creation.

## 📋 Overview

To enable gasless avatar creation, you need to:

1. **Deploy new contracts** (if not already deployed):
   - SimpleAccountFactory (ERC-4337)
   - GoldfirePaymaster (with new functions)

2. **Upgrade existing contracts** (if already deployed):
   - GoldfirePaymaster (to add new sponsorship functions)

3. **Configure and enable**:
   - Set up bundler
   - Enable paymaster sponsorship
   - Fund paymaster

## 🔍 Step 1: Check Current Deployment Status

First, check what contracts you already have deployed:

```bash
cd contracts
cat deployment.json
```

Look for:
- `GoldfirePaymaster` - Paymaster contract
- `SimpleAccountFactory` - Account factory for ERC-4337
- `EntryPoint` - ERC-4337 EntryPoint address

## 🆕 Step 2: Deploy New Contracts (If Needed)

### Option A: Deploy Everything Fresh

If you're starting fresh or want to redeploy everything:

```bash
# Deploy all contracts (including new ERC-4337 contracts)
npm run deploy:all:amoy
```

This will deploy:
- All existing contracts
- SimpleAccountFactory (ERC-4337)
- GoldfirePaymaster (with new functions)

### Option B: Deploy Only Missing Contracts

If you already have most contracts deployed, deploy only the new ones:

#### 2.1 Deploy SimpleAccountFactory

```bash
npx hardhat run scripts/deploy-account-factory.js --network amoy
```

#### 2.2 Deploy GoldfirePaymaster

```bash
npx hardhat run scripts/deploy-paymaster.js --network amoy
```

**Note**: If GoldfirePaymaster already exists, you'll need to upgrade it instead (see Step 3).

## 🔄 Step 3: Upgrade Existing Contracts

If you already have contracts deployed, you need to upgrade them to add the new functions.

### 3.1 Upgrade GoldfirePaymaster

The GoldfirePaymaster contract has been updated with:
- `sponsorAvatarCreation` flag
- `setSponsorAvatarCreation()` function
- `setAvatarRegistry()` function
- `whitelistForAvatarCreation()` function
- Updated `validateAndPay()` to auto-sponsor avatar creation

**Upgrade Script:**

```bash
npx hardhat run scripts/upgrade-paymaster.js --network amoy
```

Or manually:

```javascript
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  // Get current proxy address from deployment.json
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  const deployments = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  const proxyAddress = deployments.amoy?.GoldfirePaymaster;
  
  if (!proxyAddress) {
    throw new Error("GoldfirePaymaster not found in deployment.json");
  }
  
  console.log("Upgrading GoldfirePaymaster at:", proxyAddress);
  
  const GoldfirePaymaster = await ethers.getContractFactory("GoldfirePaymaster");
  const upgraded = await upgrades.upgradeProxy(proxyAddress, GoldfirePaymaster);
  await upgraded.waitForDeployment();
  
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log("✓ Upgraded!");
  console.log("  Proxy:", proxyAddress);
  console.log("  New Implementation:", implementationAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### 3.2 Verify Upgrade

After upgrading, verify the new functions are available:

```javascript
const paymaster = await ethers.getContractAt("GoldfirePaymaster", proxyAddress);

// Check if new function exists
try {
  const isEnabled = await paymaster.sponsorAvatarCreation();
  console.log("✓ New function available! Sponsorship enabled:", isEnabled);
} catch (e) {
  console.error("✗ Upgrade may have failed:", e.message);
}
```

## ⚙️ Step 4: Configure Contracts

### 4.1 Enable Paymaster Sponsorship

Run the setup script:

```bash
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

This script will:
- Enable `sponsorAvatarCreation` flag
- Set avatar registry address
- Optionally fund the paymaster

**Manual Configuration:**

```javascript
const paymaster = await ethers.getContractAt("GoldfirePaymaster", paymasterAddress);
const avatarRegistry = "0x..."; // Your AvatarRegistry address

// Enable sponsorship
await paymaster.setSponsorAvatarCreation(true);

// Set avatar registry
await paymaster.setAvatarRegistry(avatarRegistry);

// Fund paymaster (optional but recommended)
await paymaster.deposit({ value: ethers.parseEther("0.1") });
```

### 4.2 Verify Configuration

```javascript
const paymaster = await ethers.getContractAt("GoldfirePaymaster", paymasterAddress);

// Check sponsorship status
const isEnabled = await paymaster.sponsorAvatarCreation();
console.log("Sponsorship enabled:", isEnabled);

// Check avatar registry
const avatarRegistry = await paymaster.avatarRegistry();
console.log("Avatar registry:", avatarRegistry);

// Check balance
const balance = await ethers.provider.getBalance(paymasterAddress);
console.log("Paymaster balance:", ethers.formatEther(balance), "MATIC");
```

## 🔧 Step 5: Update Flutter App

After deploying/upgrading, update your Flutter app:

### 5.1 Update Contract Addresses

Edit `lib/constants/app_constants.dart`:

```dart
// ERC-4337 Account Abstraction Contracts
static const String goldfireTokenContractAddress = '0x...'; // From deployment.json
static const String adminRegistryContractAddress = '0x...';
static const String accountFactoryContractAddress = '0x...'; // New
static const String paymasterContractAddress = '0x...'; // Updated
static const String entryPointAddress = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';

// Bundler Configuration
static const String bundlerRpcUrl = 'https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY';
```

### 5.2 Get Addresses from deployment.json

```bash
cd contracts
cat deployment.json | grep -A 1 "GoldfirePaymaster\|SimpleAccountFactory\|AccountFactory"
```

## 📝 Step 6: Complete Setup Checklist

- [ ] Checked current deployment status
- [ ] Deployed SimpleAccountFactory (if needed)
- [ ] Deployed/Upgraded GoldfirePaymaster
- [ ] Verified upgrade successful
- [ ] Enabled paymaster sponsorship
- [ ] Set avatar registry address
- [ ] Funded paymaster with MATIC
- [ ] Configured bundler URL in Flutter app
- [ ] Updated contract addresses in Flutter app
- [ ] Tested gasless avatar creation

## 🚀 Quick Commands Reference

### Deploy Everything Fresh
```bash
npm run deploy:all:amoy
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

### Upgrade Existing Paymaster
```bash
npx hardhat run scripts/upgrade-paymaster.js --network amoy
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

### Deploy Only New Contracts
```bash
npx hardhat run scripts/deploy-account-factory.js --network amoy
npx hardhat run scripts/deploy-paymaster.js --network amoy
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

## 🔍 Troubleshooting

### "Contract already deployed"

If a contract is already deployed, you need to upgrade it instead:

```bash
# Check if contract exists
npx hardhat run scripts/check-deployment.js --network amoy

# Upgrade instead of deploy
npx hardhat run scripts/upgrade-paymaster.js --network amoy
```

### "Upgrade failed: Contract is not upgrade safe"

This means the contract has changes that violate upgrade safety. Common issues:
- Changed storage layout
- Removed functions
- Changed function signatures

**Solution**: Review the contract changes and ensure:
- Storage variables are only appended (not removed/reordered)
- Functions are only added (not removed)
- Function signatures are unchanged

### "Insufficient funds"

Make sure your deployer wallet has enough MATIC:
- Upgrade transactions cost gas
- Funding paymaster requires MATIC
- Get testnet MATIC from: https://faucet.polygon.technology/

### "Function not found after upgrade"

1. Verify the upgrade completed successfully
2. Check the implementation address changed
3. Verify the new contract code was deployed
4. Try calling the function directly on the proxy

## 📚 Related Documentation

- **[CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md)** - Full deployment guide
- **[BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md)** - Bundler configuration
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Quick bundler setup
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup guide

## 🔐 Security Notes

- **Test on testnet first** before mainnet
- **Verify contracts** on Polygonscan after deployment
- **Keep private keys secure** - never commit to git
- **Review upgrade changes** before executing
- **Test thoroughly** after upgrades

---

**Next Steps**: After deployment/upgrade, see [QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md) to configure the bundler.

