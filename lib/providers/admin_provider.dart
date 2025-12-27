import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';

/// Provider for admin status
final isAdminProvider = FutureProvider<bool>((ref) async {
  final service = AdminService();
  return await service.isAdmin();
});

/// Provider for all admin addresses
final allAdminsProvider = FutureProvider<List<String>>((ref) async {
  final service = AdminService();
  return await service.getAllAdmins();
});

/// Provider for admin count
final adminCountProvider = FutureProvider<int>((ref) async {
  final service = AdminService();
  return await service.getAdminCount();
});

/// Provider for paymaster balance
final paymasterBalanceProvider = FutureProvider<BigInt>((ref) async {
  final service = AdminService();
  return await service.getPaymasterBalance();
});

