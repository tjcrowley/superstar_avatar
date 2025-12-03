# Quick Start: Bundler Setup for Gasless Avatar Creation

This is a quick guide to get your bundler up and running in 5 minutes.

## Step 1: Choose a Bundler Service

**Recommended: Pimlico** (easiest for testing)

1. Go to [https://pimlico.io](https://pimlico.io)
2. Sign up (free)
3. Get your API key from the dashboard

## Step 2: Configure the Bundler URL

### Option A: Environment Variable (Recommended)

```bash
export BUNDLER_RPC_URL="https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_API_KEY"
```

Replace `YOUR_API_KEY` with your actual Pimlico API key.

### Option B: Update Code Directly

Edit `lib/constants/app_constants.dart`:

```dart
static const String bundlerRpcUrl = 'https://api.pimlico.io/v1/amoy/rpc?apikey=YOUR_ACTUAL_API_KEY';
```

## Step 3: Enable Paymaster Sponsorship

Run the setup script:

```bash
cd contracts
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

Make sure your `.env` file has:
```
PAYMASTER_ADDRESS=0x790450c2a8254f1a06689A327382033e8c0fD1ee
AVATAR_REGISTRY_ADDRESS=0x20be36229C7a877A3aEef3C0441B9863b026854c
PAYMASTER_FUND_AMOUNT=0.1  # Optional: fund with 0.1 MATIC
```

## Step 4: Test It

1. Run your Flutter app
2. Try creating an avatar
3. It should work without requiring MATIC!

## Troubleshooting

### "Bundler not configured" error

- Make sure you've set the `BUNDLER_RPC_URL` environment variable
- Or updated the default in `app_constants.dart`
- Check that your API key is correct

### "Paymaster validation failed"

- Run the setup script to enable sponsorship
- Make sure the paymaster has MATIC (fund it if needed)
- Check that `sponsorAvatarCreation` is enabled

### "Account not created"

- Users need to create a smart contract account first
- This happens automatically when they try to create an avatar
- Make sure the account factory contract is deployed

## Next Steps

- See `BUNDLER_SETUP_GUIDE.md` for detailed information
- See `contracts/scripts/setup-paymaster-sponsorship.js` for paymaster setup

## Alternative Bundler Services

If Pimlico doesn't work for you:

- **Stackup**: `https://api.stackup.sh/v1/node/YOUR_API_KEY`
- **Alchemy**: `https://polygon-amoy.g.alchemy.com/v2/YOUR_API_KEY`

See `BUNDLER_SETUP_GUIDE.md` for more options.

