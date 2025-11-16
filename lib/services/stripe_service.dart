import 'dart:convert';
import 'package:http/http.dart' as http;

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  // Stripe API endpoints
  static const String _stripeApiBase = 'https://api.stripe.com/v1';
  String? _secretKey;
  String? _publishableKey;

  // Initialize with API keys
  void initialize({
    required String secretKey,
    required String publishableKey,
  }) {
    _secretKey = secretKey;
    _publishableKey = publishableKey;
  }

  String? get publishableKey => _publishableKey;

  // Create Stripe Connect account for event producer
  Future<Map<String, dynamic>> createConnectAccount({
    required String email,
    required String country,
    String? businessType,
    Map<String, dynamic>? businessProfile,
  }) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/accounts');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'type': 'express',
      'country': country,
      'email': email,
      if (businessType != null) 'business_type': businessType,
      if (businessProfile != null) 'business_profile': jsonEncode(businessProfile),
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to create Connect account: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error creating Connect account: $e');
    }
  }

  // Create account link for onboarding
  Future<Map<String, dynamic>> createAccountLink({
    required String accountId,
    required String returnUrl,
    required String refreshUrl,
  }) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/account_links');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'account': accountId,
      'return_url': returnUrl,
      'refresh_url': refreshUrl,
      'type': 'account_onboarding',
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to create account link: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error creating account link: $e');
    }
  }

  // Create payment intent for ticket purchase
  Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    required String eventId,
    required String avatarId,
    String? customerId,
    String? connectedAccountId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/payment_intents');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'amount': amount.toString(),
      'currency': currency,
      'metadata[eventId]': eventId,
      'metadata[avatarId]': avatarId,
      if (customerId != null) 'customer': customerId,
      if (connectedAccountId != null) 'on_behalf_of': connectedAccountId,
      if (metadata != null) ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to create payment intent: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  // Create payment intent with application fee (for platform fee)
  Future<Map<String, dynamic>> createPaymentIntentWithFee({
    required int amount,
    required String currency,
    required String eventId,
    required String avatarId,
    required String connectedAccountId,
    required int applicationFeeAmount,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/payment_intents');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'amount': amount.toString(),
      'currency': currency,
      'application_fee_amount': applicationFeeAmount.toString(),
      'transfer_data[destination]': connectedAccountId,
      'metadata[eventId]': eventId,
      'metadata[avatarId]': avatarId,
      if (customerId != null) 'customer': customerId,
      if (metadata != null) ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to create payment intent: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  // Confirm payment intent
  Future<Map<String, dynamic>> confirmPaymentIntent({
    required String paymentIntentId,
    String? paymentMethodId,
  }) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/payment_intents/$paymentIntentId/confirm');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      if (paymentMethodId != null) 'payment_method': paymentMethodId,
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to confirm payment intent: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error confirming payment intent: $e');
    }
  }

  // Get payment intent status
  Future<Map<String, dynamic>> getPaymentIntent(String paymentIntentId) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/payment_intents/$paymentIntentId');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to get payment intent: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error getting payment intent: $e');
    }
  }

  // Create transfer to connected account (for payouts)
  Future<Map<String, dynamic>> createTransfer({
    required int amount,
    required String currency,
    required String destination,
    String? transferGroup,
    Map<String, dynamic>? metadata,
  }) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/transfers');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'amount': amount.toString(),
      'currency': currency,
      'destination': destination,
      if (transferGroup != null) 'transfer_group': transferGroup,
      if (metadata != null) ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to create transfer: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error creating transfer: $e');
    }
  }

  // Get connected account information
  Future<Map<String, dynamic>> getAccount(String accountId) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/accounts/$accountId');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to get account: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error getting account: $e');
    }
  }

  // Check if account is ready to receive payments
  Future<bool> isAccountReady(String accountId) async {
    try {
      final account = await getAccount(accountId);
      final chargesEnabled = account['charges_enabled'] as bool? ?? false;
      final payoutsEnabled = account['payouts_enabled'] as bool? ?? false;
      final detailsSubmitted = account['details_submitted'] as bool? ?? false;
      
      return chargesEnabled && payoutsEnabled && detailsSubmitted;
    } catch (e) {
      return false;
    }
  }

  // Create refund
  Future<Map<String, dynamic>> createRefund({
    required String paymentIntentId,
    int? amount,
    String? reason,
  }) async {
    if (_secretKey == null) throw Exception('Stripe not initialized');

    final url = Uri.parse('$_stripeApiBase/refunds');
    final headers = {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'payment_intent': paymentIntentId,
      if (amount != null) 'amount': amount.toString(),
      if (reason != null) 'reason': reason,
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to create refund: ${responseData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error creating refund: $e');
    }
  }
}

