# Polygon Amoy Testnet Deployment Guide

This guide will walk you through deploying the Superstar Avatar smart contracts to Polygon Amoy testnet (replacement for deprecated Mumbai testnet).

## Prerequisites

1. **Node.js and npm** (v16 or higher)
2. **A wallet with Amoy testnet MATIC** for gas fees
3. **Polygonscan API key** for contract verification (optional but recommended)

## Step 1: Get Amoy Testnet MATIC

You need testnet MATIC tokens to pay for gas fees. Get them from a faucet:

1. **Polygon Faucet**: https://faucet.polygon.technology/
   - Select "Amoy" network
   - Enter your wallet address
   - Request testnet MATIC

2. **Alchemy Faucet**: https://www.alchemy.com/faucets/polygon-amoy
   - Connect your wallet or enter address
   - Request testnet MATIC

3. **QuickNode Faucet**: https://faucet.quicknode.com/polygon/amoy

**Note**: You'll need at least 0.1 MATIC for deployment (contracts are relatively small).

## Step 2: Set Up Environment Variables

1. Navigate to the contracts directory:
```bash
cd contracts
```

2. Create a `.env` file:
```bash
touch .env
```

3. Add the following to `.env`:
```env
# Your wallet's private key (without 0x prefix)
# IMPORTANT: Never commit this file to git!
PRIVATE_KEY=your_private_key_here

# Amoy testnet RPC URL (default public endpoint)
AMOY_RPC_URL=https://rpc-amoy.polygon.technology

# Polygonscan API key (get from https://polygonscan.com/apis)
# This is optional but needed for contract verification
POLYGONSCAN_API_KEY=your_polygonscan_api_key_here
```

### Getting Your Private Key

**⚠️ SECURITY WARNING**: Your private key gives full access to your wallet. Never share it or commit it to version control.

To get your private key:
- **MetaMask**: Settings → Security & Privacy → Show Private Key
- **Other wallets**: Check your wallet's documentation

### Getting a Polygonscan API Key

1. Go to https://polygonscan.com/register
2. Create a free account
3. Go to https://polygonscan.com/myapikey
4. Create a new API key
5. Copy the key to your `.env` file

### Getting a Custom RPC URL (Optional but Recommended)

Free RPC endpoints can be slow. For better performance:

1. **Alchemy** (Free tier available):
   - Sign up at https://www.alchemy.com/
   - Create a new app
   - Select "Polygon" → "Amoy"
   - Copy the HTTP URL

2. **Infura** (Free tier available):
   - Sign up at https://infura.io/
   - Create a new project
   - Select "Polygon PoS" → "Amoy"
   - Copy the endpoint URL

3. **QuickNode** (Free tier available):
   - Sign up at https://www.quicknode.com/
   - Create an endpoint
   - Select "Polygon" → "Amoy Testnet"
   - Copy the HTTP URL

## Step 3: Install Dependencies

```bash
cd contracts
npm install
```

This installs:
- Hardhat and plugins
- OpenZeppelin contracts
- Other required dependencies

## Step 4: Compile Contracts

```bash
npm run compile
```

This compiles all Solidity contracts and checks for errors. Fix any compilation errors before proceeding.

## Step 5: Deploy to Amoy Testnet

```bash
npx hardhat run scripts/deploy.js --network amoy
```

Or if you have a deploy script in package.json:
```bash
npm run deploy:amoy
```

### What Happens During Deployment

The deployment script will:
1. Deploy `PowerVerification` contract
2. Deploy `HouseMembership` contract
3. Deploy `ActivityScripts` contract
4. Deploy `SuperstarAvatarRegistry` contract
5. Deploy `EventProducer` contract
6. Deploy `EventListings` contract (with EventProducer address)
7. Deploy `Ticketing` contract (with EventListings, EventProducer, fee percentage, and fee recipient)
8. Create initial achievements and badges
9. Authorize the deployer as a verifier
10. Create sample activity scripts
11. Save deployment addresses to `deployment.json`

### Expected Output

You should see output like:
```
Deploying contracts with the account: 0xYourAddress...
Account balance: 1000000000000000000

Deploying PowerVerification contract...
PowerVerification deployed to: 0x1234...

Deploying HouseMembership contract...
HouseMembership deployed to: 0x5678...

...

Deployment Summary:
{
  "network": "amoy",
  "deployer": "0xYourAddress",
  "contracts": {
    "PowerVerification": "0x1234...",
    "HouseMembership": "0x5678...",
    ...
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}

Deployment info saved to deployment.json
```

## Step 6: Verify Contracts on Polygonscan

Verification makes your contract source code publicly viewable on Polygonscan, which is important for transparency and trust.

```bash
npx hardhat verify --network amoy <CONTRACT_ADDRESS> [CONSTRUCTOR_ARGS]
```

For example, to verify the PowerVerification contract (no constructor args):
```bash
npx hardhat verify --network amoy 0xYourPowerVerificationAddress
```

For Ticketing contract (with constructor args):
```bash
npx hardhat verify --network amoy 0xYourTicketingAddress "0xEventListingsAddress" "0xEventProducerAddress" 500 "0xFeeRecipientAddress"
```

### Automated Verification Script

You can create a verification script. Create `contracts/scripts/verify.js`:

```javascript
const { run } = require("hardhat");

async function main() {
  const deploymentInfo = require("../deployment.json");
  const contracts = deploymentInfo.contracts;

  console.log("Verifying contracts on Polygonscan...\n");

  // Verify PowerVerification (no constructor args)
  try {
    await run("verify:verify", {
      address: contracts.PowerVerification,
      network: "amoy",
    });
    console.log("✓ PowerVerification verified");
  } catch (error) {
    console.log("✗ PowerVerification verification failed:", error.message);
  }

  // Verify HouseMembership (no constructor args)
  try {
    await run("verify:verify", {
      address: contracts.HouseMembership,
      network: "amoy",
    });
    console.log("✓ HouseMembership verified");
  } catch (error) {
    console.log("✗ HouseMembership verification failed:", error.message);
  }

  // Verify ActivityScripts (no constructor args)
  try {
    await run("verify:verify", {
      address: contracts.ActivityScripts,
      network: "amoy",
    });
    console.log("✓ ActivityScripts verified");
  } catch (error) {
    console.log("✗ ActivityScripts verification failed:", error.message);
  }

  // Verify SuperstarAvatarRegistry (no constructor args)
  try {
    await run("verify:verify", {
      address: contracts.SuperstarAvatarRegistry,
      network: "amoy",
    });
    console.log("✓ SuperstarAvatarRegistry verified");
  } catch (error) {
    console.log("✗ SuperstarAvatarRegistry verification failed:", error.message);
  }

  // Verify EventProducer (no constructor args)
  try {
    await run("verify:verify", {
      address: contracts.EventProducer,
      network: "amoy",
    });
    console.log("✓ EventProducer verified");
  } catch (error) {
    console.log("✗ EventProducer verification failed:", error.message);
  }

  // Verify EventListings (with EventProducer address)
  try {
    await run("verify:verify", {
      address: contracts.EventListings,
      constructorArguments: [contracts.EventProducer],
      network: "amoy",
    });
    console.log("✓ EventListings verified");
  } catch (error) {
    console.log("✗ EventListings verification failed:", error.message);
  }

  // Verify Ticketing (with constructor args)
  try {
    await run("verify:verify", {
      address: contracts.Ticketing,
      constructorArguments: [
        contracts.EventListings,
        contracts.EventProducer,
        500, // platform fee percentage
        deploymentInfo.deployer, // fee recipient
      ],
      network: "amoy",
    });
    console.log("✓ Ticketing verified");
  } catch (error) {
    console.log("✗ Ticketing verification failed:", error.message);
  }

  console.log("\nVerification complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Then run:
```bash
npx hardhat run scripts/verify.js --network amoy
```

## Step 7: Update Flutter App Configuration

After deployment, update your Flutter app with the contract addresses:

1. Open `lib/constants/app_constants.dart`

2. Update the contract addresses:
```dart
// Smart Contract Addresses (Amoy Testnet)
static const String powerVerificationContractAddress = '0xYourPowerVerificationAddress';
static const String houseMembershipContractAddress = '0xYourHouseMembershipAddress';
static const String activityScriptsContractAddress = '0xYourActivityScriptsAddress';
static const String superstarAvatarRegistryContractAddress = '0xYourSuperstarAvatarRegistryAddress';
static const String eventProducerContractAddress = '0xYourEventProducerAddress';
static const String eventListingsContractAddress = '0xYourEventListingsAddress';
static const String ticketingContractAddress = '0xYourTicketingAddress';
```

3. Update the RPC URL and Chain ID for Amoy:
```dart
// Blockchain Configuration (Amoy Testnet)
static const String polygonRpcUrl = 'https://rpc-amoy.polygon.technology';
static const String polygonChainId = '80002'; // Amoy testnet chain ID
static const String polygonExplorerUrl = 'https://amoy.polygonscan.com';
```

## Step 8: Test the Deployment

1. **Check on Polygonscan**:
   - Go to https://amoy.polygonscan.com/
   - Search for your contract addresses
   - Verify they're deployed and verified

2. **Test with Flutter App**:
   - Connect your wallet to Amoy testnet
   - Try creating an avatar
   - Try verifying a power
   - Try creating a house
   - Try creating an activity

3. **Check Contract Interactions**:
   - View contract read functions on Polygonscan
   - Check transaction history
   - Verify events are being emitted

## Troubleshooting

### "Insufficient funds" error
- Make sure you have enough MATIC in your wallet
- Get more from a faucet if needed

### "Nonce too high" error
- Wait a few minutes and try again
- Or manually set a higher nonce in Hardhat config

### "Contract verification failed"
- Make sure your Polygonscan API key is correct
- Wait a few minutes after deployment before verifying
- Check that constructor arguments match exactly

### "RPC rate limit exceeded"
- Use a custom RPC endpoint (Alchemy, Infura, QuickNode)
- Or wait and try again later

### Contracts not showing on Polygonscan
- Wait a few minutes for blockchain indexing
- Check that you're on the correct network (Amoy)
- Verify the transaction hash on Polygonscan

## Next Steps

1. **Test thoroughly** on Amoy before considering mainnet
2. **Document your contract addresses** for your team
3. **Set up monitoring** for contract events
4. **Plan for mainnet deployment** when ready

## Security Reminders

- ⚠️ **Never commit `.env` file to git**
- ⚠️ **Never share your private key**
- ⚠️ **Use a separate wallet for testing**
- ⚠️ **Keep your Polygonscan API key secure**
- ⚠️ **Test thoroughly on testnet before mainnet**

## Additional Resources

- [Polygon Amoy Faucet](https://faucet.polygon.technology/)
- [Polygonscan Amoy](https://amoy.polygonscan.com/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [Polygon Documentation](https://docs.polygon.technology/)

