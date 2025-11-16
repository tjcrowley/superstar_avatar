# QR Code Check-In System

This document describes the QR code-based check-in system for event producers to verify and check in ticket holders at events.

## Overview

The check-in system allows event producers to:
- Scan QR codes from attendee tickets
- Verify ticket validity on the blockchain
- Mark tickets as checked in
- Track check-in history
- Prevent duplicate check-ins

## Architecture

### Smart Contract Updates

**Ticketing.sol** has been enhanced with:

1. **QR Code Hash Storage**
   - Each ticket includes a `qrCodeHash` (bytes32) generated from ticket data
   - Mapping from QR code hash to ticket ID for quick lookup
   - Prevents QR code reuse with `qrCodeUsed` mapping

2. **Check-In Function**
   ```solidity
   function checkInTicket(bytes32 qrCodeHash) external
   ```
   - Validates QR code hash
   - Verifies ticket is valid and not already used
   - Checks event timing (within 1 hour before start to 1 hour after end)
   - Verifies caller is event producer or platform owner
   - Marks ticket as used and records check-in details

3. **Ticket Structure Updates**
   - `qrCodeHash`: Hash of QR code data
   - `checkedInAt`: Timestamp of check-in
   - `checkedInBy`: Address that performed check-in

### Flutter Implementation

#### QR Code Service (`lib/services/qr_code_service.dart`)

Provides QR code generation and validation:

- **Generate QR Code Data**: Creates JSON string with ticket information
- **Generate QR Code Hash**: Creates hash matching blockchain hash
- **Parse QR Code Data**: Validates and parses scanned QR codes
- **Generate QR Code Widget**: Creates visual QR code for display

#### Check-In Screen (`lib/screens/checkin_screen.dart`)

Full-featured check-in interface:

- **QR Scanner**: Real-time QR code scanning using `mobile_scanner`
- **Event Information**: Displays event details and check-in count
- **Processing State**: Shows loading state during check-in
- **Check-In History**: Lists recent check-ins with timestamps
- **Error Handling**: Displays error messages for invalid tickets

#### Ticket Model Updates (`lib/models/ticket.dart`)

Enhanced with check-in fields:

- `qrCodeHash`: QR code hash string
- `checkedInAt`: Check-in timestamp
- `checkedInBy`: Address that checked in the ticket
- `isCheckedIn`: Computed property for check-in status

#### Ticket QR Code Widget (`lib/widgets/ticket_qr_code.dart`)

Displays QR code on ticket:

- Visual QR code representation
- Ticket ID display
- Check-in status indicator

## Workflow

### 1. Ticket Purchase

1. User purchases ticket via Stripe
2. Ticket created on blockchain with QR code hash
3. QR code hash generated from: `ticketId:eventId:avatarId:buyerAddress:timestamp`
4. Hash stored in ticket and mapping

### 2. QR Code Display

1. User receives ticket with QR code
2. QR code contains JSON with ticket data:
   ```json
   {
     "ticketId": "ticket-123",
     "eventId": "event-456",
     "avatarId": "avatar-789",
     "buyerAddress": "0x...",
     "purchaseTime": "2024-01-01T12:00:00Z"
   }
   ```
3. QR code displayed in ticket view

### 3. Check-In Process

1. **Event Producer Opens Check-In Screen**
   - Selects event
   - Opens check-in interface

2. **Scan QR Code**
   - Scanner detects QR code
   - Parses ticket data
   - Validates format

3. **Verify Ticket**
   - Checks event ID matches
   - Generates QR code hash from data
   - Calls blockchain to verify

4. **Check In on Blockchain**
   - Calls `checkInTicket(qrCodeHash)`
   - Blockchain verifies:
     - QR code hash exists
     - Ticket is valid
     - Ticket not already used
     - Event timing is correct
     - Caller is authorized

5. **Record Check-In**
   - Ticket marked as used
   - Check-in timestamp recorded
   - Check-in address recorded
   - QR code marked as used

6. **Update UI**
   - Success message displayed
   - Check-in added to history
   - Scanner resumes for next ticket

## Security Features

### QR Code Security

1. **Hash-Based Verification**
   - QR code contains readable data for quick validation
   - Blockchain uses hash for secure verification
   - Prevents QR code tampering

2. **One-Time Use**
   - QR codes can only be used once
   - `qrCodeUsed` mapping prevents reuse
   - Ticket marked as used after check-in

3. **Event Matching**
   - QR code must match event being checked into
   - Prevents using tickets for wrong events

4. **Timing Validation**
   - Check-in only allowed within time window
   - 1 hour before event start
   - 1 hour after event end
   - Prevents early/late check-ins

5. **Authorization**
   - Only event producer can check in tickets
   - Platform owner can also check in (for support)
   - Prevents unauthorized check-ins

### Blockchain Verification

- All check-ins recorded on blockchain
- Immutable check-in history
- Transparent verification process
- Prevents double-check-in

## Usage

### For Event Producers

1. **Navigate to Check-In**
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => CheckInScreen(
         eventId: event.id,
         event: event,
       ),
     ),
   );
   ```

2. **Scan Tickets**
   - Point camera at attendee's QR code
   - System automatically processes
   - Success/error feedback provided

3. **View History**
   - Recent check-ins displayed
   - Timestamp and ticket info shown
   - Track check-in progress

### For Ticket Holders

1. **View Ticket**
   - Open ticket in app
   - QR code displayed automatically
   - Ready for scanning

2. **At Event**
   - Show QR code to event staff
   - Staff scans with check-in app
   - Instant verification

## Error Handling

### Invalid QR Code
- **Format Error**: QR code doesn't match expected format
- **Missing Data**: Required fields missing from QR code
- **Solution**: User needs valid ticket QR code

### Wrong Event
- **Event Mismatch**: QR code is for different event
- **Solution**: Use correct event's QR code

### Already Checked In
- **Duplicate Check-In**: Ticket already used
- **Solution**: Cannot check in same ticket twice

### Outside Time Window
- **Too Early**: Event hasn't started yet
- **Too Late**: Event has ended
- **Solution**: Check in during event hours

### Unauthorized
- **Not Producer**: Caller is not event producer
- **Solution**: Only event producer can check in

## Testing

### Test Scenarios

1. **Valid Check-In**
   - Scan valid QR code
   - Verify successful check-in
   - Check blockchain state

2. **Duplicate Check-In**
   - Try to check in same ticket twice
   - Verify rejection
   - Check error message

3. **Wrong Event**
   - Scan ticket for different event
   - Verify rejection
   - Check error message

4. **Invalid QR Code**
   - Scan invalid QR code
   - Verify rejection
   - Check error message

5. **Timing Validation**
   - Try check-in before event
   - Try check-in after event
   - Verify time window enforcement

## Future Enhancements

1. **Offline Mode**: Cache check-ins for offline events
2. **Batch Check-In**: Check in multiple tickets at once
3. **Check-In Analytics**: Statistics and reports
4. **Photo Capture**: Optional photo on check-in
5. **Guest List**: Pre-approved guest list
6. **VIP Check-In**: Special handling for VIP tickets
7. **Check-In Notifications**: Notify ticket holder of check-in

## Dependencies

- `mobile_scanner`: QR code scanning
- `qr_flutter`: QR code generation
- `crypto`: Hash generation
- `web3dart`: Blockchain interaction

## Permissions

Required permissions:
- **Camera**: For QR code scanning
- **Internet**: For blockchain verification

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Add to `Info.plist` (iOS):
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan ticket QR codes</string>
```

