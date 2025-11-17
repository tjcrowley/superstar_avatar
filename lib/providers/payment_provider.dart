import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import '../services/blockchain_service.dart';

/// Provider for managing payment and wallet balance state
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService = PaymentService();
  final BlockchainService _blockchainService = BlockchainService();

  PaymentNotifier() : super(PaymentState.initial());

  /// Check if wallet has sufficient balance for transactions
  Future<bool> checkBalance() async {
    try {
      final walletAddress = _blockchainService.walletAddress;
      if (walletAddress == null) return false;

      final balance = await _blockchainService.getBalance();
      final balanceMatic = balance / BigInt.from(10).pow(18);
      
      // Minimum balance: 0.01 MATIC
      final hasBalance = balanceMatic >= BigInt.from(10000000000000000); // 0.01 MATIC in wei
      
      state = state.copyWith(
        balance: balanceMatic.toDouble() / 1000000000000000000,
        hasSufficientBalance: hasBalance,
      );
      
      return hasBalance;
    } catch (e) {
      debugPrint('Error checking balance: $e');
      return false;
    }
  }

  /// Monitor balance and trigger auto-top-up if needed
  Future<void> monitorBalance() async {
    final hasBalance = await checkBalance();
    
    if (!hasBalance && state.autoTopUpEnabled) {
      // Trigger auto-top-up
      await requestAutoTopUp();
    }
  }

  /// Request automatic top-up
  Future<void> requestAutoTopUp() async {
    try {
      state = state.copyWith(isProcessingAutoTopUp: true);
      
      final walletAddress = _blockchainService.walletAddress;
      if (walletAddress == null) {
        throw Exception('Wallet not connected');
      }

      // Request default amount
      final paymentIntent = await _paymentService.createPaymentIntent(
        walletAddress: walletAddress,
        amountMatic: 0.1, // Default auto-top-up amount
        network: 'amoy',
      );

      state = state.copyWith(
        lastPaymentIntentId: paymentIntent.paymentIntentId,
        isProcessingAutoTopUp: false,
      );
    } catch (e) {
      debugPrint('Error requesting auto-top-up: $e');
      state = state.copyWith(
        isProcessingAutoTopUp: false,
        error: e.toString(),
      );
    }
  }

  /// Enable/disable auto-top-up
  void setAutoTopUp(bool enabled) {
    state = state.copyWith(autoTopUpEnabled: enabled);
  }

  /// Set auto-top-up threshold
  void setAutoTopUpThreshold(double thresholdMatic) {
    state = state.copyWith(autoTopUpThreshold: thresholdMatic);
  }
}

/// Payment State
class PaymentState {
  final double balance;
  final bool hasSufficientBalance;
  final bool autoTopUpEnabled;
  final double autoTopUpThreshold;
  final bool isProcessingAutoTopUp;
  final String? lastPaymentIntentId;
  final String? error;

  PaymentState({
    required this.balance,
    required this.hasSufficientBalance,
    this.autoTopUpEnabled = false,
    this.autoTopUpThreshold = 0.01,
    this.isProcessingAutoTopUp = false,
    this.lastPaymentIntentId,
    this.error,
  });

  factory PaymentState.initial() {
    return PaymentState(
      balance: 0.0,
      hasSufficientBalance: false,
      autoTopUpEnabled: false,
      autoTopUpThreshold: 0.01,
    );
  }

  PaymentState copyWith({
    double? balance,
    bool? hasSufficientBalance,
    bool? autoTopUpEnabled,
    double? autoTopUpThreshold,
    bool? isProcessingAutoTopUp,
    String? lastPaymentIntentId,
    String? error,
  }) {
    return PaymentState(
      balance: balance ?? this.balance,
      hasSufficientBalance: hasSufficientBalance ?? this.hasSufficientBalance,
      autoTopUpEnabled: autoTopUpEnabled ?? this.autoTopUpEnabled,
      autoTopUpThreshold: autoTopUpThreshold ?? this.autoTopUpThreshold,
      isProcessingAutoTopUp: isProcessingAutoTopUp ?? this.isProcessingAutoTopUp,
      lastPaymentIntentId: lastPaymentIntentId ?? this.lastPaymentIntentId,
      error: error ?? this.error,
    );
  }
}

// Provider
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});

