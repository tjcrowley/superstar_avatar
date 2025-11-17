import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants/app_constants.dart';
import '../services/payment_service.dart';
import '../services/blockchain_service.dart';
import '../widgets/gradient_button.dart';

/// Screen for purchasing MATIC with credit card
class PaymentScreen extends ConsumerStatefulWidget {
  final String walletAddress;
  final Function()? onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.walletAddress,
    this.onPaymentSuccess,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '0.1');
  final PaymentService _paymentService = PaymentService();
  
  bool _isProcessing = false;
  String? _errorMessage;
  double _amountMatic = 0.1;
  double _amountUSD = 0.0;
  String? _paymentIntentId;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateUSD);
    _calculateUSD();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateUSD() {
    // MATIC price (should be fetched from API in production)
    const maticPriceUSD = 0.5;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _amountMatic = amount;
      _amountUSD = amount * maticPriceUSD;
    });
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Create payment intent
      final paymentIntent = await _paymentService.createPaymentIntent(
        walletAddress: widget.walletAddress,
        amountMatic: _amountMatic,
        network: 'amoy',
      );

      _paymentIntentId = paymentIntent.paymentIntentId;

      // Confirm payment with Stripe
      await Stripe.instance.confirmPayment(
        paymentIntent.clientSecret,
        PaymentSheetParams(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          merchantDisplayName: 'Superstar Avatar',
        ),
      );

      // Poll for payment status
      await _pollPaymentStatus(paymentIntent.paymentIntentId);

    } catch (e) {
      debugPrint('Payment error: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  Future<bool> _pollPaymentStatus(String paymentIntentId) async {
    const maxAttempts = 30;
    const delay = Duration(seconds: 2);

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(delay);

      try {
        final status = await _paymentService.checkPaymentStatus(paymentIntentId);

        if (status.isCompleted) {
          // Payment successful, MATIC sent
          setState(() {
            _isProcessing = false;
          });
          return true;
        } else if (status.isFailed) {
          setState(() {
            _errorMessage = 'Payment failed. Please try again.';
            _isProcessing = false;
          });
          return false;
        }
        // Continue polling if pending
      } catch (e) {
        debugPrint('Error checking payment status: $e');
      }
    }

    // Timeout
    setState(() {
      _errorMessage = 'Payment is taking longer than expected. Please check your wallet.';
      _isProcessing = false;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase MATIC'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet Address Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Address',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.walletAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Amount Input
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (MATIC)',
                  hintText: '0.1',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < AppConstants.minMaticPurchase) {
                    return 'Minimum purchase is ${AppConstants.minMaticPurchase} MATIC';
                  }
                  if (amount > AppConstants.maxMaticPurchase) {
                    return 'Maximum purchase is ${AppConstants.maxMaticPurchase} MATIC';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // USD Amount Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Cost',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '\$${_amountUSD.toStringAsFixed(2)} USD',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.errorColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppConstants.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppConstants.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),

              // Payment Button
              GradientButton(
                onPressed: _isProcessing ? null : _handlePayment,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Pay with Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Info Text
              Text(
                'Your MATIC will be sent to your wallet immediately after payment confirmation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

