# Event Producer and Ticketing System

This document describes the event producer registration, event listing, and ticketing system integrated with Stripe for payment processing.

## Overview

The system allows avatars to register as event producers, create real-world event listings (concerts, parties, conferences, etc.), and sell tickets through a Stripe-integrated payment system. Event producers can create houses that belong to their events, and the platform collects fees from ticket sales before paying out to producers.

## Architecture

### Smart Contracts

1. **EventProducer.sol**
   - Manages event producer registration
   - Links Stripe Connect accounts to producers
   - Tracks producer statistics (events, tickets sold, revenue)
   - Supports producer verification

2. **EventListings.sol**
   - Manages real-world event listings
   - Links events to producers
   - Tracks event details (venue, location, time, pricing)
   - Supports event categories (Concert, Party, Conference, etc.)

3. **Ticketing.sol**
   - Manages ticket creation and validation
   - Tracks ticket ownership and usage
   - Integrates with Stripe payment intents
   - Handles platform fee calculation
   - Supports ticket tiers

### Flutter Services

1. **StripeService**
   - Creates Stripe Connect accounts for event producers
   - Handles payment intent creation with application fees
   - Manages account onboarding links
   - Processes transfers to connected accounts
   - Handles refunds

2. **BlockchainService** (Extended)
   - Event producer registration
   - Event creation and management
   - Ticket creation and validation
   - Stripe account linking

3. **EventProducerProvider**
   - State management for event producers
   - Stripe account linking workflow
   - Producer profile management

## Workflow

### 1. Event Producer Registration

1. Avatar registers as event producer:
   ```dart
   await eventProducerProvider.registerAsProducer(
     avatarId: avatarId,
     name: "Producer Name",
     description: "Description",
     email: "email@example.com",
     country: "US",
   );
   ```

2. System creates Stripe Connect account (optional):
   - If email and country provided, creates Express account
   - Generates account link for onboarding
   - Links account ID to producer on blockchain

3. Producer completes Stripe onboarding:
   - Redirects to Stripe onboarding URL
   - Completes business information
   - Returns to app with verified account

### 2. Event Creation

1. Producer creates event listing:
   ```dart
   await blockchainService.createEvent(
     eventId: eventId,
     producerId: producerId,
     title: "Concert Name",
     description: "Event description",
     venue: "Venue Name",
     location: "123 Main St, City, State",
     startTime: DateTime.now().add(Duration(days: 30)),
     endTime: DateTime.now().add(Duration(days: 30, hours: 3)),
     ticketPrice: 5000, // $50.00 in cents
     maxTickets: 100,
     category: 0, // EventCategory.concert
   );
   ```

2. Event is stored on blockchain with all details
3. Producer can create houses linked to the event
4. Event appears in listings for ticket purchase

### 3. Ticket Purchase Flow

1. User selects event and ticket quantity
2. System creates Stripe payment intent with application fee:
   ```dart
   final paymentIntent = await stripeService.createPaymentIntentWithFee(
     amount: ticketPrice * quantity,
     currency: 'usd',
     eventId: eventId,
     avatarId: avatarId,
     connectedAccountId: producerStripeAccountId,
     applicationFeeAmount: platformFee,
   );
   ```

3. User completes payment via Stripe
4. On successful payment, ticket is created on blockchain:
   ```dart
   await blockchainService.createTicket(
     ticketId: ticketId,
     eventId: eventId,
     avatarId: avatarId,
     price: ticketPrice,
     stripePaymentIntentId: paymentIntent['id'],
   );
   ```

5. Ticket ownership recorded on blockchain
6. Event ticket count updated

### 4. Ticket Validation

1. At event entry, validator scans ticket
2. System validates ticket on blockchain:
   ```dart
   await blockchainService.validateTicket(
     ticketId: ticketId,
   );
   ```

3. Ticket marked as used
4. Prevents duplicate entry

### 5. Payout to Event Producer

1. Platform collects payments via Stripe
2. Application fee deducted automatically
3. Remaining amount transferred to producer's Stripe account:
   ```dart
   await stripeService.createTransfer(
     amount: netAmount,
     currency: 'usd',
     destination: producerStripeAccountId,
   );
   ```

4. Producer can withdraw funds from their Stripe account

## Stripe Integration

### Platform Account Setup

1. Create Stripe account for platform
2. Enable Stripe Connect
3. Configure application fee percentage (default: 5%)
4. Set up webhook endpoints for payment events

### Event Producer Stripe Accounts

**Option 1: New Account Creation**
- Producer provides email and country
- System creates Express account
- Producer completes onboarding
- Account linked to producer profile

**Option 2: Existing Account**
- Producer provides existing Stripe account ID
- System links account to producer
- Account must be verified and ready

### Payment Processing

- **Payment Intent Creation**: Creates payment intent with application fee
- **Connected Account**: Payment goes to producer's account
- **Platform Fee**: Automatically deducted via application_fee_amount
- **Transfer**: Remaining amount available in producer's account

## Platform Fee Structure

- Default platform fee: 5% (configurable)
- Fee calculated on ticket price
- Deducted automatically via Stripe application fees
- Platform receives fee, producer receives net amount

## House Integration

Event producers can create houses that belong to their events:

1. Producer creates event
2. Producer creates house linked to event:
   ```dart
   await blockchainService.createHouse(
     name: "Event House",
     description: "House for event attendees",
     eventId: eventId,
     eventName: eventTitle,
     maxMembers: 50,
   );
   ```

3. Event attendees can join the house
4. House activities can be created for event-related engagement

## Security Considerations

1. **Access Control**: Only verified producers can create events
2. **Ticket Validation**: Tickets validated on blockchain to prevent fraud
3. **Payment Security**: All payments processed through Stripe
4. **Account Verification**: Stripe accounts must be verified before payouts
5. **Event Cancellation**: Producers can cancel events (tickets remain valid for refunds)

## Data Models

### EventProducer
- Producer ID, Avatar ID, Name, Description
- Stripe Account ID
- Statistics (events, tickets, revenue)
- Verification status

### Event
- Event ID, Producer ID, Title, Description
- Venue, Location, Start/End Time
- Ticket Price, Max Tickets, Tickets Sold
- Category, Status

### Ticket
- Ticket ID, Event ID, Avatar ID
- Buyer Address, Purchase Time
- Price, Validation Status
- Stripe Payment Intent ID

## API Integration Points

### Stripe API
- Account creation and management
- Payment intent creation
- Transfer creation
- Refund processing

### Blockchain
- Producer registration
- Event creation
- Ticket minting
- Ticket validation

## Future Enhancements

1. **Ticket Tiers**: Support for VIP, General Admission, etc.
2. **Early Bird Pricing**: Time-based pricing
3. **Group Discounts**: Bulk ticket pricing
4. **Refund System**: Automated refund processing
5. **Analytics Dashboard**: Producer analytics
6. **Mobile Check-in**: QR code scanning for validation
7. **Waitlist**: Waitlist for sold-out events

## Testing

### Test Scenarios

1. Producer registration with Stripe account
2. Event creation and listing
3. Ticket purchase flow
4. Payment processing with fees
5. Ticket validation
6. Payout to producer
7. Event cancellation and refunds

### Test Accounts

- Use Stripe test mode for development
- Test payment methods: `4242 4242 4242 4242`
- Test connected accounts in test mode

## Deployment Checklist

- [ ] Deploy EventProducer contract
- [ ] Deploy EventListings contract
- [ ] Deploy Ticketing contract
- [ ] Configure Stripe Connect
- [ ] Set up webhook endpoints
- [ ] Configure platform fee
- [ ] Test payment flow
- [ ] Test payout flow
- [ ] Set up monitoring
- [ ] Document API endpoints

## Support

For issues related to:
- **Stripe**: Check Stripe Dashboard and logs
- **Blockchain**: Check contract events and transactions
- **Integration**: Review service logs and error messages

