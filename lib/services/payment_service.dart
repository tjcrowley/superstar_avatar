import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Service for handling MATIC purchases via Stripe
class PaymentService {
  // Backend API base URL - use AppConstants
  String get _apiBaseUrl => AppConstants.backendApiUrl;

  /// Create a payment intent for MATIC purchase
  Future<PaymentIntentResponse> createPaymentIntent({
    required String walletAddress,
    required double amountMatic,
    String network = 'amoy',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_apiBaseUrl}/api/payment/create-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'walletAddress': walletAddress,
          'amountMatic': amountMatic,
          'network': network,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentIntentResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Check payment status
  Future<PaymentStatus> checkPaymentStatus(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('${_apiBaseUrl}/api/payment/status/$paymentIntentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentStatus.fromJson(data);
      } else {
        throw Exception('Failed to check payment status');
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      rethrow;
    }
  }

  /// Get wallet balance
  Future<WalletBalance> getWalletBalance(String address) async {
    try {
      final response = await http.get(
        Uri.parse('${_apiBaseUrl}/api/wallet/balance/$address'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WalletBalance.fromJson(data);
      } else {
        throw Exception('Failed to get wallet balance');
      }
    } catch (e) {
      debugPrint('Error getting wallet balance: $e');
      rethrow;
    }
  }
}

/// Payment Intent Response
class PaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;
  final double amountUSD;
  final double amountMatic;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amountUSD,
    required this.amountMatic,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['clientSecret'],
      paymentIntentId: json['paymentIntentId'],
      amountUSD: double.parse(json['amountUSD']),
      amountMatic: double.parse(json['amountMatic']),
    );
  }
}

/// Payment Status
class PaymentStatus {
  final String status;
  final double amountMatic;
  final String? txHash;
  final String walletAddress;

  PaymentStatus({
    required this.status,
    required this.amountMatic,
    this.txHash,
    required this.walletAddress,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['status'],
      amountMatic: double.parse(json['amountMatic'].toString()),
      txHash: json['txHash'],
      walletAddress: json['walletAddress'],
    );
  }

  bool get isCompleted => status == 'succeeded';
  bool get isPending => status == 'processing' || status == 'requires_payment_method';
  bool get isFailed => status == 'canceled' || status == 'payment_failed';
}

/// Wallet Balance
class WalletBalance {
  final String address;
  final double balance;
  final String balanceWei;

  WalletBalance({
    required this.address,
    required this.balance,
    required this.balanceWei,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      address: json['address'],
      balance: double.parse(json['balance']),
      balanceWei: json['balanceWei'],
    );
  }
}

