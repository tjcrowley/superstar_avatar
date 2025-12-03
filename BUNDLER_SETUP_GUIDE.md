# ERC-4337 Bundler Setup Guide

This guide will help you set up a bundler for gasless avatar creation using ERC-4337 account abstraction.

## What is a Bundler?

A bundler is a service that:
- Collects user operations (UserOps) from the mempool
- Validates and simulates them
- Bundles them together
- Submits them to the EntryPoint contract on-chain
- Pays gas fees (which are reimbursed by the paymaster)

## Option 1: Use a Public Bundler Service (Recommended for Testing)

### Pimlico (Recommended)

Pimlico provides public bundler endpoints for Polygon Amoy testnet:

**Bundler URL for Amoy Testnet:**
```
https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY
```

**Steps:**
1. Sign up at [https://pimlico.io](https://pimlico.io)
2. Get your API key from the dashboard
3. Set the environment variable:
   ```bash
   export BUNDLER_RPC_URL="https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY"
   ```

**For Flutter:**
Update `lib/constants/app_constants.dart` or set via environment:
```dart
static const String bundlerRpcUrl = String.fromEnvironment(
  'BUNDLER_RPC_URL',
  defaultValue: 'https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY',
);
```

### Stackup

Stackup also provides bundler services:

**Bundler URL for Amoy Testnet:**
```
https://api.stackup.sh/v1/node/YOUR_API_KEY
```

**Steps:**
1. Sign up at [https://stackup.sh](https://stackup.sh)
2. Get your API key
3. Use the URL above with your API key

### Alchemy

Alchemy provides bundler services through their AA SDK:

**Bundler URL:**
```
https://polygon-amoy.g.alchemy.com/v2/YOUR_API_KEY
```

**Steps:**
1. Sign up at [https://alchemy.com](https://alchemy.com)
2. Create an app for Polygon Amoy
3. Get your API key
4. Use the URL above

## Option 2: Run Your Own Bundler (Advanced)

### Using Voltaire (Open Source)

Voltaire is a Python-based bundler that's easy to set up:

**Prerequisites:**
- Python 3.9+
- Node.js (for running a local node or connecting to RPC)

**Steps:**

1. Clone the repository:
   ```bash
   git clone https://github.com/candidelabs/voltaire
   cd voltaire
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure for Polygon Amoy:
   Create a `config.yaml`:
   ```yaml
   network:
     rpc_url: "https://rpc-amoy.polygon.technology"
     chain_id: 80002
     entry_point: "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"
   
   bundler:
     port: 3000
     host: "0.0.0.0"
   ```

4. Run the bundler:
   ```bash
   python main.py
   ```

5. Your bundler will be available at:
   ```
   http://localhost:3000
   ```

### Using Stackup Bundler (Docker)

1. Pull the Docker image:
   ```bash
   docker pull stackup/stackup-bundler:latest
   ```

2. Run with environment variables:
   ```bash
   docker run -d \
     -p 4337:4337 \
     -e ETH_CLIENT_URL=https://rpc-amoy.polygon.technology \
     -e ENTRY_POINT_ADDRESS=0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789 \
     -e PRIVATE_KEY=YOUR_BUNDLER_PRIVATE_KEY \
     stackup/stackup-bundler:latest
   ```

## Configuration

### 1. Update Flutter Constants

Edit `lib/constants/app_constants.dart`:

```dart
// For Pimlico (replace with your API key)
static const String bundlerRpcUrl = 'https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY';

// Or use environment variable
static const String bundlerRpcUrl = String.fromEnvironment(
  'BUNDLER_RPC_URL',
  defaultValue: 'https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY',
);
```

### 2. Set Environment Variables

**For Flutter development:**
```bash
# macOS/Linux
export BUNDLER_RPC_URL="https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY"

# Windows (PowerShell)
$env:BUNDLER_RPC_URL="https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY"
```

**For Android/iOS builds:**
You'll need to set these in your build configuration or use a `.env` file with a package like `flutter_dotenv`.

### 3. Enable Paymaster Sponsorship

Before users can create gasless avatars:

1. Deploy your paymaster contract (if not already deployed)
2. Fund the paymaster with MATIC
3. Enable sponsorship:
   ```javascript
   // In Hardhat console or script
   const paymaster = await ethers.getContractAt("GoldfirePaymaster", PAYMASTER_ADDRESS);
   await paymaster.setSponsorAvatarCreation(true);
   ```

## Testing the Bundler

### Test User Operation

You can test if your bundler is working:

```dart
final accountAbstraction = AccountAbstractionService();

// Create a test user operation
final userOp = await accountAbstraction.createUserOperation(
  to: avatarRegistryAddress,
  data: callData,
  paymasterAndData: await accountAbstraction.getPaymasterData(),
);

// Estimate gas
final gasEstimate = await accountAbstraction.estimateUserOperationGas(userOp);

// Send to bundler
final userOpHash = await accountAbstraction.sendUserOperation(userOp);
print('UserOp hash: $userOpHash');
```

## Troubleshooting

### "Bundler not found" or Connection Errors

1. **Check the URL**: Ensure the bundler URL is correct
2. **Check API Key**: Verify your API key is valid
3. **Network**: Ensure you're using the correct network (Amoy testnet)
4. **CORS**: If running locally, ensure CORS is enabled

### "Paymaster validation failed"

1. **Check Paymaster Balance**: Ensure paymaster has enough MATIC
2. **Check Sponsorship**: Verify `sponsorAvatarCreation` is enabled
3. **Check Whitelist**: Ensure user is whitelisted (or auto-whitelisting is enabled)

### "User operation reverted"

1. **Check Gas Limits**: Ensure gas limits are sufficient
2. **Check EntryPoint**: Verify EntryPoint address is correct
3. **Check Contract**: Ensure target contract exists and function is correct

## Production Considerations

1. **Rate Limiting**: Implement rate limiting to prevent abuse
2. **Monitoring**: Set up monitoring for bundler health
3. **Backup Bundlers**: Use multiple bundler endpoints for redundancy
4. **Error Handling**: Implement proper error handling and retries
5. **Gas Price**: Monitor gas prices and adjust paymaster funding

## Resources

- [ERC-4337 Documentation](https://docs.erc4337.io/)
- [Pimlico Documentation](https://docs.pimlico.io/)
- [Stackup Documentation](https://docs.stackup.sh/)
- [Alchemy AA SDK](https://docs.alchemy.com/docs/account-abstraction-sdk)

## Next Steps

1. Choose a bundler service (Pimlico recommended for testing)
2. Get your API key
3. Update `AppConstants.bundlerRpcUrl`
4. Test with a simple user operation
5. Enable paymaster sponsorship
6. Test gasless avatar creation

