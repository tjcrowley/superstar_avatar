# IPFS Setup Guide

This guide explains how to set up IPFS API keys for image uploads in the Superstar Avatar app. The app supports two IPFS pinning services: **Pinata** (recommended) and **NFT.Storage** (fallback).

## Overview

The app uses IPFS (InterPlanetary File System) to store images for:
- Avatar profile images
- Activity images

Images are uploaded to IPFS when selected, and the IPFS hash (CID) is stored on the blockchain.

## Option 1: Pinata (Recommended)

Pinata is a popular IPFS pinning service that provides reliable storage and fast access to your files.

### Step 1: Create a Pinata Account

1. Go to [https://www.pinata.cloud/](https://www.pinata.cloud/)
2. Click "Sign Up" and create a free account
3. Verify your email address

### Step 2: Get Your API Keys

1. Log in to your Pinata dashboard
2. Click on your profile icon (top right)
3. Select "API Keys" from the dropdown menu
4. Click "New Key" button
5. Configure the key:
   - **Key Name**: Enter a name (e.g., "Superstar Avatar App")
   - **Key Permissions**: Select "PinFileToIPFS" (or "Admin" for full access)
   - **Optional**: Set an expiration date
6. Click "Create Key"
7. **IMPORTANT**: Copy both values:
   - **API Key** (looks like: `abc123def456...`)
   - **Secret API Key** (looks like: `xyz789uvw012...`)
   - ⚠️ The Secret API Key is only shown once! Save it immediately.

### Step 3: Configure in the App

Open `lib/services/ipfs_service.dart` and update the constants:

```dart
const pinataApiKey = 'YOUR_PINATA_API_KEY_HERE';
const pinataSecretKey = 'YOUR_PINATA_SECRET_KEY_HERE';
```

**Better Approach**: Store keys in environment variables or a config file (not committed to git):

1. Create a file `lib/config/ipfs_config.dart`:

```dart
class IPFSConfig {
  static const String pinataApiKey = String.fromEnvironment('PINATA_API_KEY', defaultValue: '');
  static const String pinataSecretKey = String.fromEnvironment('PINATA_SECRET_KEY', defaultValue: '');
  static const String nftStorageApiKey = String.fromEnvironment('NFT_STORAGE_API_KEY', defaultValue: '');
}
```

2. Update `lib/services/ipfs_service.dart` to use the config:

```dart
import '../config/ipfs_config.dart';

// Then in the uploadImageToPinata method:
final pinataApiKey = IPFSConfig.pinataApiKey;
final pinataSecretKey = IPFSConfig.pinataSecretKey;
```

3. Run the app with environment variables:

```bash
flutter run --dart-define=PINATA_API_KEY=your_key_here --dart-define=PINATA_SECRET_KEY=your_secret_here
```

## Option 2: NFT.Storage (Alternative)

NFT.Storage is a free IPFS storage service by Protocol Labs, specifically designed for NFT metadata and assets.

### Step 1: Get an API Key

1. Go to [https://nft.storage/](https://nft.storage/)
2. Click "Get Started" or "Sign In"
3. Sign in with your email or GitHub account
4. Once logged in, click on "API Keys" in the navigation
5. Click "Create API Key"
6. Give it a name (e.g., "Superstar Avatar App")
7. Copy the API key (looks like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

### Step 2: Configure in the App

Open `lib/services/ipfs_service.dart` and update:

```dart
const nftStorageApiKey = 'YOUR_NFT_STORAGE_API_KEY_HERE';
```

Or use the environment variable approach described above for Pinata.

## Current Implementation

The current implementation in `lib/services/ipfs_service.dart` has placeholder values:

```dart
const pinataApiKey = 'YOUR_PINATA_API_KEY'; // TODO: Add to app_constants
const pinataSecretKey = 'YOUR_PINATA_SECRET_KEY'; // TODO: Add to app_constants
```

When you try to upload an image without configuring the keys, you'll see an error message directing you to set up the API keys.

## Testing Your Setup

1. Configure your API keys (using one of the methods above)
2. Run the app: `flutter run`
3. Go to "Edit Profile" or "Author Activity"
4. Select an image
5. The image should upload to IPFS and you should see a success message
6. The IPFS hash will be saved to the blockchain when you save

## IPFS Gateways

The app uses multiple IPFS gateways to access images:

1. **Primary**: `https://ipfs.io/ipfs/` (IPFS Public Gateway)
2. **Secondary**: `https://gateway.pinata.cloud/ipfs/` (Pinata Gateway)
3. **Tertiary**: `https://cloudflare-ipfs.com/ipfs/` (Cloudflare Gateway)

Images are accessed via: `https://ipfs.io/ipfs/{CID}` where `{CID}` is the IPFS hash.

## Troubleshooting

### "Pinata API keys not configured" Error

- Make sure you've set the `pinataApiKey` and `pinataSecretKey` constants
- Verify the keys are correct (no extra spaces, correct format)
- Check that the keys have the necessary permissions in Pinata

### "Failed to upload to IPFS" Error

- Check your internet connection
- Verify your API keys are valid and not expired
- Check Pinata/NFT.Storage service status
- Review the error message in the app logs for more details

### Images Not Displaying

- IPFS gateways can sometimes be slow or unavailable
- The app will try multiple gateways automatically
- If images consistently fail to load, check:
  - The IPFS hash (CID) is correct in the blockchain
  - The file was successfully pinned (check Pinata dashboard)
  - Your network connection is working

### File Size Limits

- **Pinata Free Tier**: 1 GB total storage, 100 MB per file
- **NFT.Storage Free Tier**: 31 GB total storage, 100 MB per file
- For larger files, consider upgrading your plan

## Security Best Practices

1. **Never commit API keys to git**
   - Use environment variables or a config file that's in `.gitignore`
   - Add `lib/config/ipfs_config.dart` to `.gitignore` if it contains keys

2. **Use separate keys for development and production**
   - Create different API keys for testing vs. production
   - Limit key permissions to only what's needed

3. **Rotate keys periodically**
   - Change API keys if they're exposed
   - Set expiration dates on keys if supported

4. **Monitor usage**
   - Check your Pinata/NFT.Storage dashboard regularly
   - Set up alerts for unusual activity

## Advanced Configuration

### Using Environment Variables (Recommended)

Create a `.env` file (add to `.gitignore`):

```
PINATA_API_KEY=your_key_here
PINATA_SECRET_KEY=your_secret_here
NFT_STORAGE_API_KEY=your_nft_storage_key_here
```

Use a package like `flutter_dotenv` to load these values:

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

```dart
// lib/main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

```dart
// lib/services/ipfs_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final pinataApiKey = dotenv.env['PINATA_API_KEY'] ?? '';
final pinataSecretKey = dotenv.env['PINATA_SECRET_KEY'] ?? '';
```

## Support

- **Pinata Support**: [https://docs.pinata.cloud/](https://docs.pinata.cloud/)
- **NFT.Storage Docs**: [https://nft.storage/docs/](https://nft.storage/docs/)
- **IPFS Documentation**: [https://docs.ipfs.tech/](https://docs.ipfs.tech/)

## Next Steps

1. Set up your API keys using one of the methods above
2. Test image uploads in the app
3. Monitor your IPFS storage usage
4. Consider implementing automatic key rotation for production
