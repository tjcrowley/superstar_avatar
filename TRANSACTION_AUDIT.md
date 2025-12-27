# Blockchain Transaction Audit - Paymaster Integration

This document audits all blockchain transactions in the app to ensure they're routed through the paymaster for gasless execution.

## ✅ Current Status

### Transactions Currently Using Paymaster (via Account Abstraction)

1. **Avatar Creation** (`createAvatarProfile`)
   - ✅ Uses account abstraction when bundler is configured
   - ✅ Auto-whitelists users
   - ✅ Falls back to regular transaction if account abstraction fails

### Transactions NOT Yet Using Paymaster

All other transactions currently use direct `sendTransaction` calls, which require MATIC:

#### BlockchainService Methods:
1. `verifyPower` - Power verification
2. `createHouse` - House creation
3. `joinHouse` - Join a house
4. `leaveHouse` - Leave a house
5. `proposeHouseActivity` - Propose house activity
6. `voteOnActivity` - Vote on activity
7. `leaderApproveActivity` - Leader approve activity
8. `completeHouseActivity` - Complete house activity
9. `createActivityScript` - Create activity script
10. `completeActivity` - Complete activity
11. `verifyActivity` - Verify activity
12. `updateAvatarProfile` - Update avatar profile
13. `updateAvatarImage` - Update avatar image
14. `updateAvatarHouse` - Update avatar house

#### GoldfireTokenService Methods:
1. `transfer` - Transfer tokens
2. `approve` - Approve tokens
3. `mint` - Mint tokens (admin only)

#### AdminService Methods:
1. `addAdmin` - Add admin
2. `removeAdmin` - Remove admin
3. `depositToPaymaster` - Deposit to paymaster
4. `withdrawFromPaymaster` - Withdraw from paymaster
5. `addUserToWhitelist` - Add user to whitelist
6. `registerEventProducer` - Register event producer
7. `whitelistUserForAvatarCreation` - Whitelist user
8. `whitelistUserForAllTransactions` - Whitelist user for all transactions

#### AccountAbstractionService Methods:
1. `createAccount` - Create smart contract account (requires MATIC for initial creation)

## 🔧 Solution: TransactionService

A new `TransactionService` has been created that:
- Routes all transactions through account abstraction when possible
- Falls back to regular transactions if account abstraction fails
- Auto-whitelists users for gasless transactions
- Checks paymaster sponsorship status

## 📋 Implementation Plan

### Phase 1: Update Paymaster Contract ✅
- [x] Add `sponsorAllTransactions` flag
- [x] Add `setSponsorAllTransactions()` function
- [x] Add `whitelistForAllTransactions()` function
- [x] Update `validateAndPay()` to sponsor all transactions when enabled

### Phase 2: Update Admin Service ✅
- [x] Add `isAllTransactionsSponsored()` function
- [x] Add `setSponsorAllTransactions()` function
- [x] Add `whitelistUserForAllTransactions()` function

### Phase 3: Create Transaction Service ✅
- [x] Create `TransactionService` class
- [x] Implement account abstraction routing
- [x] Implement fallback to regular transactions
- [x] Auto-whitelist users

### Phase 4: Update All Transaction Calls (TODO)
- [ ] Update `BlockchainService` to use `TransactionService`
- [ ] Update `GoldfireTokenService` to use `TransactionService`
- [ ] Update `AdminService` to use `TransactionService` (for user-facing operations)
- [ ] Keep admin operations as regular transactions (they require admin privileges)

### Phase 5: Enable All Transactions Sponsorship
- [ ] Deploy/upgrade paymaster with new functions
- [ ] Enable `sponsorAllTransactions` flag
- [ ] Fund paymaster with MATIC
- [ ] Test all transactions are gasless

## 🎯 Recommended Approach

### Option 1: Update All Services to Use TransactionService (Recommended)

Replace all `_client.sendTransaction()` calls with `TransactionService.sendTransaction()`:

```dart
// Before
final txHash = await _client.sendTransaction(
  _credentials,
  transaction,
  chainId: int.parse(AppConstants.polygonChainId),
);

// After
final transactionService = TransactionService();
final txHash = await transactionService.sendTransaction(
  contract: contract,
  function: function,
  parameters: params,
);
```

### Option 2: Create Wrapper in BlockchainService

Add a helper method in `BlockchainService` that uses `TransactionService`:

```dart
Future<String> _sendTransactionWithPaymaster({
  required DeployedContract contract,
  required ContractFunction function,
  required List<dynamic> parameters,
  EtherAmount? value,
}) async {
  final transactionService = TransactionService();
  return await transactionService.sendTransaction(
    contract: contract,
    function: function,
    parameters: parameters,
    value: value,
  );
}
```

Then replace all `_client.sendTransaction()` calls with this helper.

## 📝 Files to Update

### High Priority (User-Facing Operations)
1. `lib/services/blockchain_service.dart` - All user transaction methods
2. `lib/services/goldfire_token_service.dart` - Token operations
3. `lib/providers/activity_authoring_provider.dart` - Activity creation

### Medium Priority (Admin Operations - Keep as Regular Transactions)
- Admin operations should remain as regular transactions since they require admin privileges and MATIC

### Low Priority (Account Creation)
- `createAccount` in `AccountAbstractionService` - This requires MATIC for initial account creation, which is acceptable

## ⚠️ Important Notes

1. **Account Creation**: The first account creation requires MATIC. After that, all transactions can be gasless.

2. **Admin Operations**: Admin operations (like funding paymaster, adding admins) should remain as regular transactions since they require admin privileges.

3. **Fallback**: All transactions fall back to regular transactions if account abstraction fails, ensuring the app continues to work even if bundler is not configured.

4. **Whitelisting**: Users are automatically whitelisted when they perform their first transaction, so no manual whitelisting is needed.

## 🚀 Quick Enable All Transactions Sponsorship

After deploying the updated paymaster:

```bash
cd contracts
npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
```

Then in the script or manually:

```javascript
const paymaster = await ethers.getContractAt("GoldfirePaymaster", paymasterAddress);
await paymaster.setSponsorAllTransactions(true);
```

## 📊 Transaction Count

- **Total Transaction Methods**: ~25
- **User-Facing Methods**: ~15
- **Admin Methods**: ~8
- **Account Creation**: ~2

## ✅ Next Steps

1. Deploy/upgrade paymaster with new functions
2. Enable `sponsorAllTransactions` flag
3. Update `BlockchainService` to use `TransactionService`
4. Update `GoldfireTokenService` to use `TransactionService`
5. Test all transactions are gasless
6. Update documentation

---

**Last Updated**: 2024
**Status**: TransactionService created, paymaster updated, ready for integration

