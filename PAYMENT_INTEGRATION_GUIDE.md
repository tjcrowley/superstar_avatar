# Payment Integration Guide

Complete guide for integrating Stripe payments for MATIC purchases in Superstar Avatar.

## Overview

The payment system allows users to purchase MATIC (Polygon's native token) using credit cards via Stripe. This is integrated as the **first step** in wallet setup, ensuring users have gas for transactions.

## Architecture

```
User Flow:
1. User clicks "Create Identity"
2. Wallet is generated (address created)
3. Payment screen appears automatically
4. User enters credit card and purchases MATIC
5. Backend receives payment via Stripe webhook
6. Backend sends MATIC to user's wallet
7. User proceeds with wallet setup (save mnemonic)
```

## Components

### Backend Service (`backend/`)

- **Stripe Integration**: Handles payment processing
- **Webhook Handler**: Receives payment confirmations from Stripe
- **MATIC Distribution**: Sends MATIC to user wallets after payment
- **Rate Limiting**: Prevents abuse
- **Balance API**: Allows checking wallet balances

### Flutter App

- **PaymentScreen**: UI for credit card input and MATIC purchase
- **PaymentService**: Communicates with backend API
- **PaymentProvider**: Manages payment state and auto-top-up
- **Wallet Setup Integration**: Payment required before wallet setup completion

## Setup Instructions

### 1. Backend Setup

#### Install Dependencies

```bash
cd backend
npm install
```

#### Configure Environment

Create `backend/.env`:

```env
# Server
PORT=3000
NODE_ENV=production
ALLOWED_ORIGINS=https://your-app-domain.com

# Stripe
STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=pk_live_your_stripe_publishable_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Polygon
POLYGON_RPC_URL=https://polygon-rpc.com
NETWORK=polygon

# Funder Wallet (must be funded with MATIC)
FUNDER_PRIVATE_KEY=your_funder_wallet_private_key

# MATIC Price (update periodically)
MATIC_PRICE_USD=0.5
```

#### Fund the Funder Wallet

The funder wallet must have MATIC to send to users:

```bash
# For mainnet, purchase MATIC and send to funder wallet address
# Keep enough MATIC for expected user purchases
```

#### Set Up Stripe Webhook

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/webhooks)
2. Add endpoint: `https://your-backend.com/api/webhook/stripe`
3. Select events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
4. Copy webhook signing secret to `STRIPE_WEBHOOK_SECRET`

#### Deploy Backend

Deploy to your preferred platform:
- Heroku
- AWS (EC2, Lambda)
- Google Cloud Platform
- Railway
- Render

### 2. Flutter App Setup

#### Update Constants

In `lib/constants/app_constants.dart`, the backend URL is already configured:

```dart
static const String backendApiUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'http://localhost:3000',
);
```

#### Set Environment Variables

For production builds:

```bash
# Android
flutter build apk --dart-define=BACKEND_API_URL=https://your-backend.com --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_...

# iOS
flutter build ios --dart-define=BACKEND_API_URL=https://your-backend.com --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_...
```

Or configure in your CI/CD pipeline.

#### Install Dependencies

```bash
flutter pub get
```

### 3. Testing

#### Test Mode

1. Use Stripe test keys in backend `.env`
2. Use testnet (Amoy) in backend
3. Test payment flow with Stripe test cards:
   - Success: `4242 4242 4242 4242`
   - Decline: `4000 0000 0000 0002`

#### Test Flow

1. Create new wallet
2. Payment screen should appear
3. Enter test card details
4. Complete payment
5. Verify MATIC arrives in wallet
6. Continue with wallet setup

## Payment Flow Details

### Step 1: Create Payment Intent

```dart
final paymentIntent = await paymentService.createPaymentIntent(
  walletAddress: '0x...',
  amountMatic: 0.1,
  network: 'amoy',
);
```

Backend creates Stripe Payment Intent and returns `clientSecret`.

### Step 2: Present Payment Sheet

```dart
await Stripe.instance.initPaymentSheet(...);
await Stripe.instance.presentPaymentSheet();
```

User enters card details in Stripe's secure payment sheet.

### Step 3: Webhook Processing

When payment succeeds:
1. Stripe sends webhook to backend
2. Backend verifies webhook signature
3. Backend sends MATIC to user's wallet
4. Backend stores transaction record

### Step 4: Status Polling

Flutter app polls for payment status until MATIC is received.

## Auto-Top-Up Feature

The `PaymentProvider` includes auto-top-up functionality:

```dart
// Enable auto-top-up
ref.read(paymentProvider.notifier).setAutoTopUp(true);

// Set threshold (default: 0.01 MATIC)
ref.read(paymentProvider.notifier).setAutoTopUpThreshold(0.05);

// Monitor balance
await ref.read(paymentProvider.notifier).monitorBalance();
```

When balance falls below threshold, automatically request top-up.

## Security Considerations

### Backend

- ✅ Webhook signature verification
- ✅ Rate limiting
- ✅ Input validation
- ✅ Secure private key storage
- ✅ HTTPS only
- ✅ CORS configuration

### Flutter

- ✅ Stripe handles card data (never touches your servers)
- ✅ HTTPS API calls
- ✅ Secure storage for wallet data
- ✅ No sensitive data in logs

## Pricing Strategy

### Recommended Amounts

- **Minimum**: 0.01 MATIC (~$0.005)
- **Default**: 0.1 MATIC (~$0.05)
- **Maximum**: 10.0 MATIC (~$5.00)

### Fee Structure

- Stripe fees: ~2.9% + $0.30 per transaction
- Your margin: Add markup if desired
- MATIC price: Update periodically or fetch from API

## Monitoring

### Backend Logs

Monitor for:
- Payment intent creation
- Webhook events
- MATIC transfer transactions
- Errors and failures

### Metrics to Track

- Payment success rate
- Average purchase amount
- Time to MATIC delivery
- Failed payment reasons
- Funder wallet balance

## Production Checklist

- [ ] Backend deployed and accessible
- [ ] Stripe webhook configured
- [ ] Funder wallet funded with MATIC
- [ ] Environment variables set
- [ ] HTTPS enabled
- [ ] Rate limiting configured
- [ ] Monitoring set up
- [ ] Error alerting configured
- [ ] MATIC price update mechanism
- [ ] Database for payment records (replace in-memory storage)
- [ ] Retry logic for failed MATIC transfers

## Troubleshooting

### Payment Intent Creation Fails

- Check backend is running
- Verify API URL is correct
- Check network connectivity
- Review backend logs

### MATIC Not Received

- Check webhook is configured correctly
- Verify funder wallet has balance
- Check backend logs for errors
- Verify transaction on Polygonscan

### Payment Sheet Doesn't Appear

- Verify Stripe publishable key is set
- Check Stripe initialization in `main.dart`
- Ensure `flutter_stripe` package is installed
- Review Flutter logs

## Support

For issues:
1. Check backend logs
2. Check Stripe Dashboard for payment status
3. Verify webhook events in Stripe
4. Check Polygonscan for MATIC transfers

