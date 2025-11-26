# Wallet Funding Guide

This guide explains how to automatically fund new wallets with MATIC for gas fees, and how to enable gasless transactions using ERC-4337 account abstraction.

## Overview

When users create a new wallet, they traditionally need MATIC (Polygon's native token) to pay for gas fees. However, with ERC-4337 account abstraction and paymaster integration, **avatar creation is now gasless** - users don't need MATIC to create their first avatar!

## Gasless Avatar Creation (Recommended)

The app now supports **gasless avatar creation** using ERC-4337 account abstraction:

- ✅ **No MATIC required** for users to create avatars
- ✅ **Automatic sponsorship** via paymaster
- ✅ **Better user experience** - no need to fund wallets first

### Setup Gasless Avatar Creation

1. **Deploy Paymaster** (see [CONTRACT_DEPLOYMENT_GUIDE.md](CONTRACT_DEPLOYMENT_GUIDE.md))
2. **Configure Bundler** (see [BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md) or [QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md))
3. **Enable Sponsorship**:
   ```bash
   cd contracts
   npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
   ```

For detailed instructions, see:
- **[QUICK_START_BUNDLER.md](QUICK_START_BUNDLER.md)** - Quick 5-minute setup
- **[BUNDLER_SETUP_GUIDE.md](BUNDLER_SETUP_GUIDE.md)** - Comprehensive guide

## Traditional Wallet Funding (Fallback)

If you're not using gasless transactions, or for other operations that require MATIC, this guide covers several approaches to automatically fund wallets.

## Approaches

### 1. Testnet: Automatic Faucet Integration (Recommended for Development)

For testnet (Amoy), you can automatically request MATIC from faucets:

#### Option A: Backend Faucet Service (Best for Production)

Create a backend service that:
1. Receives wallet addresses
2. Sends small amounts of testnet MATIC from a funded account
3. Implements rate limiting and anti-abuse measures

**Backend Example (Node.js/Express):**

```javascript
const express = require('express');
const { ethers } = require('ethers');
const app = express();

// Funded account for sending MATIC
const FUNDER_PRIVATE_KEY = process.env.FUNDER_PRIVATE_KEY;
const FUNDER_WALLET = new ethers.Wallet(FUNDER_PRIVATE_KEY);
const PROVIDER = new ethers.JsonRpcProvider('https://rpc-amoy.polygon.technology');

// Rate limiting (simple in-memory store - use Redis in production)
const requests = new Map();

app.use(express.json());

app.post('/api/faucet', async (req, res) => {
  const { address, network } = req.body;
  
  // Validate address
  if (!ethers.isAddress(address)) {
    return res.status(400).json({ error: 'Invalid address' });
  }
  
  // Rate limiting: 1 request per address per hour
  const now = Date.now();
  const lastRequest = requests.get(address);
  if (lastRequest && (now - lastRequest) < 3600000) {
    return res.status(429).json({ 
      error: 'Rate limit exceeded. Please wait before requesting again.' 
    });
  }
  
  try {
    // Send 0.1 MATIC
    const tx = await FUNDER_WALLET.sendTransaction({
      to: address,
      value: ethers.parseEther('0.1'),
    });
    
    await tx.wait();
    requests.set(address, now);
    
    res.json({ 
      success: true, 
      txHash: tx.hash,
      message: 'MATIC sent successfully' 
    });
  } catch (error) {
    console.error('Faucet error:', error);
    res.status(500).json({ error: 'Failed to send MATIC' });
  }
});

app.listen(3000, () => {
  console.log('Faucet service running on port 3000');
});
```

**Update Flutter Service:**

In `lib/services/faucet_service.dart`, set:
```dart
static const String? backendFaucetUrl = 'https://your-backend.com/api/faucet';
```

#### Option B: Smart Contract Faucet

Deploy a faucet contract that users can call:

```solidity
// contracts/src/Faucet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Faucet is Ownable, ReentrancyGuard {
    uint256 public constant AMOUNT = 0.1 ether;
    uint256 public constant COOLDOWN = 1 hours;
    
    mapping(address => uint256) public lastRequest;
    
    constructor() Ownable(msg.sender) {}
    
    function requestTokens() external nonReentrant {
        require(
            block.timestamp >= lastRequest[msg.sender] + COOLDOWN,
            "Cooldown period not elapsed"
        );
        
        lastRequest[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(AMOUNT);
    }
    
    // Owner can fund the faucet
    receive() external payable {}
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
```

### 2. Mainnet: Backend Funding Service

For mainnet, you **must** use a backend service with a funded account:

1. **Create a funded account** with MATIC
2. **Deploy backend service** (similar to testnet example above)
3. **Implement security measures**:
   - Rate limiting per address/IP
   - CAPTCHA verification
   - Amount limits
   - Monitoring and alerts

### 3. Account Abstraction (Advanced)

Use ERC-4337 Account Abstraction for gasless transactions:

- Users don't need MATIC
- Gas is paid by a paymaster contract
- More complex to implement
- Requires smart contract wallet infrastructure

## Implementation Status

### Current Implementation

✅ **Faucet Service Created** (`lib/services/faucet_service.dart`)
- Basic structure for requesting MATIC
- Backend integration ready
- Balance checking utilities

✅ **Wallet Creation Integration**
- Automatically requests funding after wallet creation
- Shows user-friendly messages
- Falls back to manual faucet instructions

### Next Steps

1. **For Testnet:**
   - Set up backend faucet service (see Option A above)
   - Update `backendFaucetUrl` in `faucet_service.dart`
   - Deploy and test

2. **For Mainnet:**
   - Create funded account
   - Deploy secure backend service
   - Implement rate limiting and security
   - Update `backendFaucetUrl` for mainnet

3. **Optional Enhancements:**
   - Add CAPTCHA for faucet requests
   - Implement referral system (refer friends, get bonus MATIC)
   - Add balance monitoring and auto-top-up
   - Create admin dashboard for faucet management

## Security Considerations

⚠️ **Important Security Measures:**

1. **Rate Limiting**: Prevent abuse with per-address/IP limits
2. **Amount Limits**: Limit how much MATIC can be requested
3. **Monitoring**: Track requests and detect suspicious activity
4. **CAPTCHA**: Add CAPTCHA for public-facing faucets
5. **Whitelisting**: For mainnet, consider whitelisting verified users
6. **Multi-sig**: Use multi-sig wallet for funded account (mainnet)

## Cost Estimates

### Testnet (Amoy)
- Cost: Free (testnet tokens)
- Recommended per wallet: 0.1-0.5 MATIC
- No real cost

### Mainnet (Polygon)
- Cost: Real MATIC
- Recommended per wallet: 0.01-0.05 MATIC (enough for ~10-50 transactions)
- Example: 1000 users × 0.05 MATIC = 50 MATIC (~$30-50 USD)

## Testing

Test the faucet service:

```dart
// In your Flutter app
final faucetService = FaucetService();
final success = await faucetService.requestTestnetMatic(
  walletAddress: '0x...',
  network: 'amoy',
);
```

## Resources

- [Polygon Faucet](https://faucet.polygon.technology/)
- [Alchemy Faucet](https://www.alchemy.com/faucets/polygon-amoy)
- [ERC-4337 Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

