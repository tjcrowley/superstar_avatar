# AvatarRegistry Deployment Guide

## Overview

The `AvatarRegistry` contract is an **upgradeable** smart contract that manages avatar profiles on the Polygon blockchain. It uses OpenZeppelin's UUPS (Universal Upgradeable Proxy Standard) pattern for upgradeability.

## Features

- ✅ **Upgradeable Contract**: Uses UUPS proxy pattern for future upgrades
- ✅ **Avatar Profile Storage**: Stores name, bio, image URI, and metadata on-chain
- ✅ **Image Management**: Supports updating avatar images (IPFS hashes)
- ✅ **Ownership Control**: Only avatar owners can update their profiles
- ✅ **Moderation**: Contract owner can deactivate/reactivate avatars

## Prerequisites

1. Install dependencies:
```bash
cd contracts
npm install
```

2. Set up environment variables in `contracts/.env`:
```env
PRIVATE_KEY=your_private_key_here
AMOY_RPC_URL=https://rpc-amoy.polygon.technology
POLYGON_RPC_URL=https://polygon-rpc.com
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

## Deployment Steps

### 1. Compile Contracts

```bash
cd contracts
npm run compile
```

### 2. Deploy to Amoy Testnet

```bash
npm run deploy:avatar-registry:amoy
```

Or manually:
```bash
npx hardhat run scripts/deploy-avatar-registry.js --network amoy
```

### 3. Deploy to Polygon Mainnet

```bash
npm run deploy:avatar-registry:polygon
```

Or manually:
```bash
npx hardhat run scripts/deploy-avatar-registry.js --network polygon
```

## Contract Addresses

After deployment, update `lib/constants/app_constants.dart`:

```dart
static const String avatarRegistryContractAddress = '0x...'; // Your deployed proxy address
```

**Important**: Always use the **proxy address**, not the implementation address, in your Flutter app.

## Upgrading the Contract

To upgrade the contract in the future:

```bash
npx hardhat run scripts/upgrade-avatar-registry.js --network amoy
```

This will:
1. Deploy a new implementation
2. Update the proxy to point to the new implementation
3. Preserve all existing data

## Verification

Verify the proxy and implementation contracts on Polygonscan:

```bash
# Verify implementation
npx hardhat verify --network amoy <IMPLEMENTATION_ADDRESS> <INITIAL_OWNER>

# Note: Proxy verification is automatic on Polygonscan
```

## Flutter Integration

The Flutter app is already configured to interact with `AvatarRegistry`:

1. **Create Avatar Profile**: Called automatically when creating an avatar
2. **Update Profile**: Available via the Edit Profile screen
3. **Update Image**: Supports changing avatar images
4. **Sync from Blockchain**: Avatar provider syncs profile data from blockchain

## Image Storage

Currently, the contract stores image URIs (IPFS hashes). To fully implement image storage:

1. **Upload to IPFS**: Integrate with Pinata, NFT.Storage, or similar service
2. **Get IPFS Hash**: Store the hash in the contract
3. **Display Images**: Use IPFS gateway URLs (e.g., `https://ipfs.io/ipfs/<hash>`)

Example IPFS integration:
```dart
// TODO: Implement IPFS upload
final ipfsHash = await uploadToIPFS(imageFile);
await blockchainService.updateAvatarImage(
  avatarId: avatarId,
  newImageUri: 'ipfs://$ipfsHash',
);
```

## Security Notes

- ⚠️ **Private Key Security**: Never commit private keys to version control
- ⚠️ **Proxy Ownership**: The deployer becomes the contract owner - secure this address
- ⚠️ **Upgrade Authorization**: Only the owner can upgrade the contract
- ⚠️ **Image Validation**: Consider validating IPFS hashes before storing

## Gas Costs

Estimated gas costs (Amoy testnet):
- `createAvatar`: ~150,000 gas
- `updateAvatar`: ~80,000 gas
- `updateAvatarImage`: ~60,000 gas
- `getAvatar`: Free (view function)

## Troubleshooting

### "Avatar ID already exists"
- Each wallet can only have one avatar
- Check if avatar already exists: `getAvatarIdByAddress(walletAddress)`

### "Not the avatar owner"
- Only the wallet that created the avatar can update it
- Verify wallet connection matches avatar's wallet address

### Image not displaying
- Verify IPFS hash is correct
- Check IPFS gateway is accessible
- Ensure image URI format is correct (`ipfs://<hash>` or full URL)

## Next Steps

1. Deploy contract to Amoy testnet
2. Update contract address in `app_constants.dart`
3. Test avatar creation and updates
4. Integrate IPFS for image storage
5. Deploy to Polygon mainnet when ready

