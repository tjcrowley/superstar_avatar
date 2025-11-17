require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bodyParser = require('body-parser');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { ethers } = require('ethers');
const winston = require('winston');

const app = express();
const PORT = process.env.PORT || 3000;

// Logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ],
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Stripe rate limiting (more restrictive)
const stripeLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10 // limit each IP to 10 payment requests per hour
});

// Initialize Polygon provider
const provider = new ethers.JsonRpcProvider(
  process.env.POLYGON_RPC_URL || 'https://rpc-amoy.polygon.technology'
);

// Funded wallet for sending MATIC
const funderWallet = new ethers.Wallet(
  process.env.FUNDER_PRIVATE_KEY,
  provider
);

// MATIC price in USD (update this periodically or fetch from API)
const MATIC_PRICE_USD = parseFloat(process.env.MATIC_PRICE_USD || '0.5');

// Minimum and maximum purchase amounts
const MIN_PURCHASE_MATIC = 0.01;
const MAX_PURCHASE_MATIC = 10.0;

// Store pending payments (in production, use Redis or database)
const pendingPayments = new Map();

/**
 * Create a Stripe Payment Intent for MATIC purchase
 */
app.post('/api/payment/create-intent', stripeLimiter, async (req, res) => {
  try {
    const { walletAddress, amountMatic, network = 'amoy' } = req.body;

    // Validate inputs
    if (!ethers.isAddress(walletAddress)) {
      return res.status(400).json({ error: 'Invalid wallet address' });
    }

    const amount = parseFloat(amountMatic);
    if (isNaN(amount) || amount < MIN_PURCHASE_MATIC || amount > MAX_PURCHASE_MATIC) {
      return res.status(400).json({ 
        error: `Amount must be between ${MIN_PURCHASE_MATIC} and ${MAX_PURCHASE_MATIC} MATIC` 
      });
    }

    // Calculate USD amount
    const amountUSD = amount * MATIC_PRICE_USD;
    const amountCents = Math.round(amountUSD * 100);

    // Create Stripe Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: 'usd',
      metadata: {
        walletAddress,
        amountMatic: amount.toString(),
        network,
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Store pending payment
    pendingPayments.set(paymentIntent.id, {
      walletAddress,
      amountMatic: amount,
      network,
      status: 'pending',
      createdAt: Date.now(),
    });

    logger.info(`Payment intent created: ${paymentIntent.id} for ${walletAddress}, ${amount} MATIC`);

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amountUSD: amountUSD.toFixed(2),
      amountMatic: amount.toFixed(4),
    });
  } catch (error) {
    logger.error('Error creating payment intent:', error);
    res.status(500).json({ error: 'Failed to create payment intent' });
  }
});

/**
 * Webhook endpoint for Stripe events
 */
app.post('/api/webhook/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    logger.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;
    await handlePaymentSuccess(paymentIntent);
  } else if (event.type === 'payment_intent.payment_failed') {
    const paymentIntent = event.data.object;
    await handlePaymentFailure(paymentIntent);
  }

  res.json({ received: true });
});

/**
 * Handle successful payment - send MATIC to wallet
 */
async function handlePaymentSuccess(paymentIntent) {
  try {
    const paymentData = pendingPayments.get(paymentIntent.id);
    if (!paymentData) {
      logger.error(`Payment data not found for intent: ${paymentIntent.id}`);
      return;
    }

    const { walletAddress, amountMatic, network } = paymentData;

    // Send MATIC to user's wallet
    const tx = await funderWallet.sendTransaction({
      to: walletAddress,
      value: ethers.parseEther(amountMatic.toString()),
    });

    await tx.wait();

    // Update payment status
    paymentData.status = 'completed';
    paymentData.txHash = tx.hash;
    paymentData.completedAt = Date.now();

    logger.info(`MATIC sent: ${tx.hash} to ${walletAddress}, ${amountMatic} MATIC`);

    // In production, save to database
    // await savePaymentToDatabase(paymentData);
  } catch (error) {
    logger.error('Error sending MATIC:', error);
    // In production, implement retry logic or alert system
  }
}

/**
 * Handle failed payment
 */
async function handlePaymentFailure(paymentIntent) {
  const paymentData = pendingPayments.get(paymentIntent.id);
  if (paymentData) {
    paymentData.status = 'failed';
    paymentData.failedAt = Date.now();
    logger.warn(`Payment failed: ${paymentIntent.id}`);
  }
}

/**
 * Check payment status
 */
app.get('/api/payment/status/:paymentIntentId', async (req, res) => {
  try {
    const { paymentIntentId } = req.params;
    
    const paymentData = pendingPayments.get(paymentIntentId);
    if (!paymentData) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    // Also check with Stripe for latest status
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    res.json({
      status: paymentIntent.status,
      amountMatic: paymentData.amountMatic,
      txHash: paymentData.txHash || null,
      walletAddress: paymentData.walletAddress,
    });
  } catch (error) {
    logger.error('Error checking payment status:', error);
    res.status(500).json({ error: 'Failed to check payment status' });
  }
});

/**
 * Get wallet balance
 */
app.get('/api/wallet/balance/:address', async (req, res) => {
  try {
    const { address } = req.params;
    
    if (!ethers.isAddress(address)) {
      return res.status(400).json({ error: 'Invalid address' });
    }

    const balance = await provider.getBalance(address);
    const balanceMatic = ethers.formatEther(balance);

    res.json({
      address,
      balance: balanceMatic,
      balanceWei: balance.toString(),
    });
  } catch (error) {
    logger.error('Error getting balance:', error);
    res.status(500).json({ error: 'Failed to get balance' });
  }
});

/**
 * Health check
 */
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    network: process.env.NETWORK || 'amoy',
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
  logger.info(`Network: ${process.env.NETWORK || 'amoy'}`);
  logger.info(`Funder wallet: ${funderWallet.address}`);
});

