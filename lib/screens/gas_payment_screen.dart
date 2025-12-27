import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';
import '../constants/app_constants.dart';
import '../services/goldfire_token_service.dart';
import '../services/admin_service.dart';
import '../services/blockchain_service.dart';
import '../widgets/gradient_button.dart';

/// Screen for selecting gas payment method (native vs Goldfire tokens)
class GasPaymentScreen extends ConsumerStatefulWidget {
  final Function(String paymentMethod)? onPaymentMethodSelected;
  
  const GasPaymentScreen({
    super.key,
    this.onPaymentMethodSelected,
  });

  @override
  ConsumerState<GasPaymentScreen> createState() => _GasPaymentScreenState();
}

class _GasPaymentScreenState extends ConsumerState<GasPaymentScreen> {
  final GoldfireTokenService _goldfireTokenService = GoldfireTokenService();
  final AdminService _adminService = AdminService();
  final BlockchainService _blockchainService = BlockchainService();
  
  String _selectedMethod = 'native'; // 'native' or 'goldfire'
  BigInt _goldfireBalance = BigInt.zero;
  bool _isWhitelisted = false;
  BigInt _nativeDeposit = BigInt.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  Future<void> _loadPaymentInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_blockchainService.isWalletConnected && _blockchainService.walletAddress != null) {
        // Get Goldfire balance
        _goldfireBalance = await _goldfireTokenService.getMyBalance();
        
        // Get payment info from paymaster
        final paymentInfo = await _adminService.getUserPaymentInfo(
          _blockchainService.walletAddress!,
        );
        
        _isWhitelisted = paymentInfo['hasWhitelist'] as bool;
        _nativeDeposit = paymentInfo['nativeDeposit'] as BigInt;
      }
    } catch (e) {
      debugPrint('Error loading payment info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveGoldfireForGas(BigInt amount) async {
    try {
      final paymasterAddress = AppConstants.paymasterContractAddress;
      final txHash = await _goldfireTokenService.approve(paymasterAddress, amount);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval submitted: $txHash'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        await _loadPaymentInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Payment Method'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select how you want to pay for gas fees',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // Native Token Option
            Card(
              child: RadioListTile<String>(
                title: const Text('Native Token (MATIC)'),
                subtitle: Text(
                  _nativeDeposit > BigInt.zero
                      ? 'Deposit: ${EtherAmount.fromBigInt(EtherUnit.wei, _nativeDeposit).getValueInUnit(EtherUnit.ether).toStringAsFixed(4)} MATIC'
                      : 'Pay directly from wallet',
                ),
                value: 'native',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Goldfire Token Option
            Card(
              child: RadioListTile<String>(
                title: const Text('Goldfire Tokens (GF)'),
                subtitle: FutureBuilder<String>(
                  future: _goldfireTokenService.formatAmount(_goldfireBalance),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text('Balance: ${snapshot.data} GF');
                    }
                    return const Text('Loading balance...');
                  },
                ),
                value: 'goldfire',
                groupValue: _selectedMethod,
                onChanged: _goldfireBalance > BigInt.zero
                    ? (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      }
                    : null,
              ),
            ),
            
            if (_isWhitelisted) ...[
              const SizedBox(height: 16),
              Card(
                color: AppConstants.successColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppConstants.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are whitelisted for gasless transactions!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            if (_selectedMethod == 'goldfire' && _goldfireBalance > BigInt.zero) ...[
              Text(
                'Approve Goldfire tokens for gas payments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GradientButton(
                onPressed: () async {
                  // Approve a large amount for convenience
                  final approvalAmount = BigInt.from(10).pow(18) * BigInt.from(1000); // 1000 GF
                  await _approveGoldfireForGas(approvalAmount);
                },
                child: const Text('Approve 1000 GF for Gas'),
              ),
              const SizedBox(height: 16),
            ],
            
            GradientButton(
              onPressed: () {
                widget.onPaymentMethodSelected?.call(_selectedMethod);
                Navigator.of(context).pop();
              },
              child: const Text('Confirm Payment Method'),
            ),
          ],
        ),
      ),
    );
  }
}

