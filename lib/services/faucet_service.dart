import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for automatically funding new wallets with testnet MATIC
class FaucetService {
  // Polygon Amoy testnet faucet endpoints
  static const String polygonFaucetUrl = 'https://faucet.polygon.technology/';
  static const String alchemyFaucetUrl = 'https://www.alchemy.com/faucets/polygon-amoy';
  
  // For mainnet, you'll need a backend service
  static const String? backendFaucetUrl = null; // Set this to your backend endpoint

  /// Request testnet MATIC from Polygon faucet
  /// Note: This uses the public faucet which may have rate limits
  /// For production, use a backend service
  Future<bool> requestTestnetMatic({
    required String walletAddress,
    String network = 'amoy', // 'amoy' for testnet
  }) async {
    try {
      // For testnet, we can try the Polygon faucet API if available
      // Note: Most faucets require manual interaction or have API keys
      // This is a placeholder - you'll need to implement based on available APIs
      
      debugPrint('Requesting testnet MATIC for: $walletAddress');
      
      // Option 1: If you have a backend service
      if (backendFaucetUrl != null) {
        return await _requestFromBackend(walletAddress);
      }
      
      // Option 2: Direct faucet API (if available)
      // Most public faucets don't have public APIs, so this may not work
      // You'll need to check if Polygon provides an API
      
      // For now, return false and show user instructions
      debugPrint('No backend faucet configured. User must request manually.');
      return false;
    } catch (e) {
      debugPrint('Error requesting testnet MATIC: $e');
      return false;
    }
  }

  /// Request MATIC from backend service
  Future<bool> _requestFromBackend(String walletAddress) async {
    if (backendFaucetUrl == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse(backendFaucetUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': walletAddress,
          'network': 'amoy', // or 'polygon' for mainnet
          'amount': '0.1', // Amount in MATIC
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting from backend: $e');
      return false;
    }
  }

  /// Get faucet URL for manual requests
  String getFaucetUrl({String network = 'amoy'}) {
    if (network == 'amoy') {
      return polygonFaucetUrl;
    }
    return polygonFaucetUrl;
  }

  /// Check if wallet has sufficient balance
  /// Returns true if balance is above threshold (0.01 MATIC)
  Future<bool> hasSufficientBalance({
    required String walletAddress,
    required Future<BigInt> Function() getBalance,
    BigInt? minBalance,
  }) async {
    final minBalanceValue = minBalance ?? BigInt.from(10000000000000000); // 0.01 MATIC in wei
    try {
      final balance = await getBalance();
      return balance >= minBalanceValue;
    } catch (e) {
      debugPrint('Error checking balance: $e');
      return false;
    }
  }
}

