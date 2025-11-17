# Superstar Avatar Backend Service

Backend service for handling MATIC/POL purchases via Stripe and funding user wallets.

## Features

- **Stripe Payment Integration**: Accept credit card payments for MATIC purchases
- **Automatic Wallet Funding**: Send MATIC to user wallets after successful payment
- **Webhook Support**: Handle Stripe payment events securely
- **Rate Limiting**: Prevent abuse with rate limiting
- **Balance Checking**: API endpoint to check wallet balances

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and fill in:

```bash
cp .env.example .env
```

Required variables:
- `STRIPE_SECRET_KEY`: Your Stripe secret key
- `STRIPE_WEBHOOK_SECRET`: Stripe webhook signing secret
- `FUNDER_PRIVATE_KEY`: Private key of wallet that will send MATIC
- `POLYGON_RPC_URL`: Polygon RPC endpoint
- `NETWORK`: 'amoy' for testnet or 'polygon' for mainnet

### 3. Fund the Funder Wallet

The funder wallet must have MATIC to send to users:

```bash
# For testnet, get MATIC from faucet
# For mainnet, purchase MATIC and send to funder wallet
```

### 4. Set Up Stripe Webhook

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://your-domain.com/api/webhook/stripe`
3. Select events: `payment_intent.succeeded`, `payment_intent.payment_failed`
4. Copy the webhook signing secret to `STRIPE_WEBHOOK_SECRET`

### 5. Run the Server

```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### POST `/api/payment/create-intent`

Create a Stripe Payment Intent for MATIC purchase.

**Request:**
```json
{
  "walletAddress": "0x...",
  "amountMatic": 0.1,
  "network": "amoy"
}
```

**Response:**
```json
{
  "clientSecret": "pi_...",
  "paymentIntentId": "pi_...",
  "amountUSD": "0.05",
  "amountMatic": "0.1000"
}
```

### GET `/api/payment/status/:paymentIntentId`

Check payment status.

**Response:**
```json
{
  "status": "succeeded",
  "amountMatic": 0.1,
  "txHash": "0x...",
  "walletAddress": "0x..."
}
```

### GET `/api/wallet/balance/:address`

Get wallet balance.

**Response:**
```json
{
  "address": "0x...",
  "balance": "0.1234",
  "balanceWei": "123400000000000000"
}
```

### POST `/api/webhook/stripe`

Stripe webhook endpoint (handles payment events).

## Security

- Rate limiting on all endpoints
- Helmet.js for security headers
- CORS configuration
- Webhook signature verification
- Input validation

## Production Considerations

1. **Database**: Replace in-memory `pendingPayments` with Redis or PostgreSQL
2. **Monitoring**: Add monitoring and alerting
3. **Retry Logic**: Implement retry for failed MATIC transfers
4. **Price Updates**: Fetch MATIC price from API (CoinGecko, etc.)
5. **Multi-sig**: Use multi-sig wallet for funder (mainnet)
6. **Logging**: Enhanced logging and error tracking

## Testing

```bash
npm test
```

## Deployment

Deploy to:
- Heroku
- AWS (EC2, Lambda)
- Google Cloud Platform
- DigitalOcean
- Railway
- Render

Make sure to:
- Set environment variables
- Configure webhook URL
- Fund the funder wallet
- Set up monitoring

