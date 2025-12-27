import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';
import '../services/goldfire_token_service.dart';

/// Provider for Goldfire token balance
final goldfireBalanceProvider = FutureProvider<BigInt>((ref) async {
  final service = GoldfireTokenService();
  return await service.getMyBalance();
});

/// Provider for Goldfire token formatted balance
final goldfireBalanceFormattedProvider = FutureProvider<String>((ref) async {
  final service = GoldfireTokenService();
  final balance = await service.getMyBalance();
  return await service.formatAmount(balance);
});

/// Provider for Goldfire token total supply
final goldfireTotalSupplyProvider = FutureProvider<BigInt>((ref) async {
  final service = GoldfireTokenService();
  return await service.getTotalSupply();
});

