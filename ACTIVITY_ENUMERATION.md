# Activity Enumeration Implementation Guide

## Overview

This document explains the implementation of activity enumeration in the ActivityScripts smart contract, replacing the placeholder `getActivitiesByType()` function with a fully functional system.

## Implementation Strategy

We've implemented a **hybrid approach** that combines:
1. **On-chain storage** for efficient queries
2. **Event indexing** for historical data and off-chain services

## Contract Changes

### New Storage Variables

```solidity
// Activity enumeration - track all activity IDs for efficient queries
string[] public allActivityIds; // All activity IDs
mapping(ActivityType => string[]) public activitiesByType; // activityType => activityId[]
mapping(PowerType => string[]) public activitiesByPower; // powerType => activityId[]
mapping(string => string[]) public activitiesByAuthor; // authorId => activityId[]
```

### Updated Functions

#### 1. `createActivityScript()` - Now tracks activities
When an activity is created, it's automatically added to:
- `allActivityIds[]` - Master list of all activities
- `activitiesByType[activityType][]` - Filtered by activity type
- `activitiesByPower[primaryPower][]` - Filtered by primary power
- `activitiesByPower[secondaryPower[i]][]` - Also added to secondary powers
- `activitiesByAuthor[authorId][]` - Filtered by author

#### 2. `getActivitiesByType()` - Now fully functional
```solidity
function getActivitiesByType(ActivityType activityType) external view returns (string[] memory activityIds) {
    return activitiesByType[activityType];
}
```

#### 3. New Functions Added

- **`getAllActivityIds()`** - Returns all activity IDs
- **`getActivityCount()`** - Returns total number of activities
- **`getActivitiesByAuthor()`** - Returns activities by author ID
- **`getActivitiesByPower()`** - Now fully functional (was placeholder)

## Gas Costs

### Storage Costs (One-time, per activity)
- `allActivityIds.push()`: ~20,000 gas
- `activitiesByType[].push()`: ~20,000 gas
- `activitiesByPower[].push()` (primary): ~20,000 gas
- `activitiesByPower[].push()` (each secondary): ~20,000 gas
- `activitiesByAuthor[].push()`: ~20,000 gas

**Total per activity**: ~100,000-180,000 gas (depending on number of secondary powers)

### Query Costs (Read operations, no gas)
- `getAllActivityIds()`: Free (view function)
- `getActivitiesByType()`: Free (view function)
- `getActivitiesByPower()`: Free (view function)
- `getActivitiesByAuthor()`: Free (view function)

## Benefits

### ✅ Advantages
1. **Efficient On-Chain Queries**: No need to iterate through all activities
2. **Multiple Filter Options**: Filter by type, power, or author
3. **Real-Time Data**: Always up-to-date with contract state
4. **No External Dependencies**: Works entirely on-chain
5. **Backward Compatible**: Existing code continues to work

### ⚠️ Considerations
1. **Gas Costs**: Additional storage costs when creating activities (~100k-180k gas)
2. **Array Growth**: Arrays grow over time, but Solidity handles this efficiently
3. **No Deletion**: Activities can't be removed from arrays (only deactivated)

## Migration Strategy

### For Existing Contracts

If you have an existing contract with activities already created:

1. **Option A: Deploy New Contract**
   - Deploy updated contract
   - Migrate activities (if needed)
   - Update Flutter app with new contract address

2. **Option B: Add Migration Function** (if contract is upgradeable)
   ```solidity
   function migrateExistingActivities() external onlyOwner {
       // Iterate through existing activities and add to arrays
       // This would require tracking existing activities
   }
   ```

### For New Deployments

Simply deploy the updated contract - all new activities will be automatically tracked.

## Flutter Integration

The Flutter app has been updated to use the new functions:

```dart
// Get all activities (now uses contract function directly)
final activityIds = await blockchainService.getAllActivityIds();

// Get activities by type
final activityIds = await blockchainService.getActivitiesByType(activityType);

// Get activities by author
final activityIds = await blockchainService.getActivitiesByAuthor(authorId);

// Get activity count
final count = await blockchainService.getActivityCount();
```

## Event Indexing (Optional Enhancement)

For even better performance and historical queries, you can also index events:

```javascript
// Example: Index ActivityScriptCreated events
const events = await contract.queryFilter(
  contract.filters.ActivityScriptCreated()
);

events.forEach(event => {
  const activityId = event.args.activityId;
  const activityType = event.args.activityType;
  // Store in your database/index
});
```

## Best Practices

1. **Use On-Chain Queries for Real-Time Data**: Use contract functions for current state
2. **Use Event Indexing for Historical Data**: Index events for analytics and history
3. **Cache Results**: Cache activity lists in Flutter app to reduce RPC calls
4. **Pagination**: For large lists, consider implementing pagination in the contract
5. **Monitor Gas Costs**: Track gas costs as activity count grows

## Future Enhancements

Potential improvements:
1. **Pagination Support**: Add `getActivitiesByTypePaginated(offset, limit)`
2. **Filtering**: Add `getActiveActivitiesByType()` to filter by `isActive`
3. **Sorting**: Add sorting options (by date, popularity, etc.)
4. **Search**: Add text search capabilities (would require off-chain indexing)

## Testing

Test the enumeration functions:

```javascript
// In Hardhat tests
const activityIds = await contract.getAllActivityIds();
expect(activityIds.length).to.equal(3);

const personalResources = await contract.getActivitiesByType(0); // PersonalResources
expect(personalResources.length).to.equal(1);

const courageActivities = await contract.getActivitiesByPower(0); // Courage
expect(courageActivities.length).to.be.greaterThan(0);
```

## Conclusion

This implementation provides efficient, on-chain activity enumeration while maintaining reasonable gas costs. The system scales well and provides multiple query options for different use cases.

