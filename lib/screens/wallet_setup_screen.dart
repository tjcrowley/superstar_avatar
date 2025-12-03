import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../services/blockchain_service.dart';
import '../services/faucet_service.dart';
import '../services/payment_service.dart';
import '../services/account_abstraction_service.dart';
import '../services/admin_service.dart';
import '../providers/wallet_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/secure_text_field.dart';
import 'payment_screen.dart';

class WalletSetupScreen extends ConsumerStatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  ConsumerState<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends ConsumerState<WalletSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mnemonicController = TextEditingController();
  bool _isCreatingWallet = false;
  bool _isImportingWallet = false;
  bool _showMnemonic = false;
  String? _generatedMnemonic;
  String? _walletAddress;
  bool _isRequestingFunding = false;
  bool _hasCompletedPayment = false;
  final FaucetService _faucetService = FaucetService();
  final PaymentService _paymentService = PaymentService();

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    setState(() {
      _isCreatingWallet = true;
    });

    try {
      // Use the singleton BlockchainService instance
      final blockchainService = BlockchainService();
      final mnemonic = await blockchainService.createWallet();
      final walletAddress = blockchainService.walletAddress;

      debugPrint('WalletSetupScreen._createWallet: Created wallet with address: $walletAddress');

      if (walletAddress == null) {
        throw Exception('Failed to get wallet address after creation');
      }

      // Create smart contract account via Account Factory (gasless initial setup)
      try {
        final aaService = AccountAbstractionService();
        final adminService = AdminService();
        
        // Check if user should be whitelisted for gasless setup
        // For now, we'll attempt to create the account
        // The paymaster will sponsor if user is whitelisted
        final accountTxHash = await aaService.createAccount();
        debugPrint('Smart contract account creation submitted: $accountTxHash');
        
        // Add user to paymaster whitelist for initial setup (if admin)
        // In production, this should be done by a backend service
        final isAdmin = await adminService.isAdmin();
        if (isAdmin) {
          try {
            await adminService.addUserToWhitelist(walletAddress);
            debugPrint('User added to paymaster whitelist');
          } catch (e) {
            debugPrint('Could not add user to whitelist (may not be admin): $e');
          }
        }
      } catch (e) {
        debugPrint('Error creating smart contract account: $e');
        // Continue with wallet creation even if SCA creation fails
      }

      // Connect wallet via provider immediately after creation
      // This ensures the wallet state is updated and AppRouter knows the wallet is connected
      // Pass null because wallet is already created in the singleton
      debugPrint('WalletSetupScreen._createWallet: Calling connectWallet(null) to update provider state');
      await ref.read(walletProvider.notifier).connectWallet(null);
      debugPrint('WalletSetupScreen._createWallet: connectWallet completed');
      
      // Store wallet info temporarily
      setState(() {
        _generatedMnemonic = mnemonic;
        _walletAddress = walletAddress;
        _isCreatingWallet = false;
      });

      // Navigate to payment screen FIRST (before showing mnemonic)
      final paymentSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            walletAddress: walletAddress,
            onPaymentSuccess: () {
              setState(() {
                _hasCompletedPayment = true;
              });
            },
          ),
        ),
      );

      if (paymentSuccess == true) {
        // Payment successful, now show mnemonic
        setState(() {
          _hasCompletedPayment = true;
          _showMnemonic = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Please save your recovery phrase.'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } else {
        // Payment cancelled or failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment required to continue. Your wallet has been created.'),
              backgroundColor: AppConstants.warningColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create identity: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      setState(() {
        _isCreatingWallet = false;
      });
    }
  }

  /// Request initial MATIC funding for new wallet
  Future<void> _requestInitialFunding(String walletAddress) async {
    setState(() {
      _isRequestingFunding = true;
    });

    try {
      // Try to request testnet MATIC automatically
      final success = await _faucetService.requestTestnetMatic(
        walletAddress: walletAddress,
        network: 'amoy',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Testnet MATIC requested! It may take a few minutes to arrive.'),
              backgroundColor: AppConstants.successColor,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // Show instructions for manual faucet request
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Get testnet MATIC from the faucet to start using your identity.'),
              backgroundColor: AppConstants.warningColor,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open Faucet',
                textColor: Colors.white,
                onPressed: () async {
                  final url = Uri.parse(_faucetService.getFaucetUrl(network: 'amoy'));
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting initial funding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not auto-request MATIC. Please use the faucet manually.'),
            backgroundColor: AppConstants.warningColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isRequestingFunding = false;
      });
    }
  }

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isImportingWallet = true;
    });

    try {
      final mnemonic = _mnemonicController.text.trim();
      
      // Connect wallet via provider first - this will import the wallet into the singleton
      await ref.read(walletProvider.notifier).connectWallet(mnemonic);
      
      // Get wallet address from the singleton after import
      final blockchainService = BlockchainService();
      final walletAddress = blockchainService.walletAddress;

      setState(() {
        _walletAddress = walletAddress;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity imported successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import identity: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isImportingWallet = false;
      });
    }
  }

  Future<void> _confirmMnemonic() async {
    if (_generatedMnemonic == null) return;
    
    setState(() {
      _showMnemonic = false;
    });
    
    try {
      // Store the mnemonic securely now that user has confirmed they saved it
      await ref.read(walletProvider.notifier).storeCreatedWalletMnemonic(_generatedMnemonic!);
      
      // Connect wallet via provider to trigger AppRouter rebuild
      await ref.read(walletProvider.notifier).connectWallet(_generatedMnemonic);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity saved! Your identity will be restored automatically on next launch.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save identity: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't watch isWalletConnectedProvider here to avoid rebuild loop with AppRouter
    // AppRouter is already watching this provider and will handle navigation automatically
    // We only check the local _walletAddress state to show loading
    if (_walletAddress != null) {
      // Wallet was just created/imported, show loading while AppRouter navigates
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppConstants.spacingL),
                Text(
                  'Identity connected! Setting up your experience...',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // App Logo and Title
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusXXL),
                    boxShadow: AppConstants.shadowLarge,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingL),
                
                Text(
                  'Welcome to Superstar Avatar',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.spacingM),
                
                Text(
                  'Connect your identity to start your journey',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.spacingXL),

                // Wallet Address Display (only show if wallet is connected but not yet navigated)
                if (_walletAddress != null && !_showMnemonic) ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                      border: Border.all(color: AppConstants.primaryColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Identity Connected',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Text(
                          '${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  // AppRouter will automatically navigate when wallet state changes
                  // Show loading indicator while navigation happens
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Navigating to app...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Mnemonic Display
                if (_showMnemonic && _generatedMnemonic != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppConstants.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                      border: Border.all(color: AppConstants.warningColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: AppConstants.warningColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Text(
                              'Save Your Recovery Phrase',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppConstants.warningColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text(
                          _generatedMnemonic!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text(
                          'Write this down and keep it safe. You\'ll need it to recover your identity.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  GradientButton(
                    onPressed: _confirmMnemonic,
                    child: const Text('I\'ve Saved My Recovery Phrase'),
                  ),
                ] else if (_walletAddress == null) ...[
                  // Create Wallet Button
                  GradientButton(
                    onPressed: _isCreatingWallet ? null : _createWallet,
                    child: _isCreatingWallet
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create New Identity'),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Or Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Import Wallet Section
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showMnemonic = false;
                        _generatedMnemonic = null;
                      });
                    },
                    child: const Text('Import Existing Identity'),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingL),
                  
                  // Mnemonic Input
                  SecureTextField(
                    controller: _mnemonicController,
                    labelText: 'Recovery Phrase',
                    hintText: 'Enter your 12 or 24 word recovery phrase',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your recovery phrase';
                      }
                      final words = value.trim().split(' ');
                      if (words.length != 12 && words.length != 24) {
                        return 'Recovery phrase must be 12 or 24 words';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  GradientButton(
                    onPressed: _isImportingWallet ? null : _importWallet,
                    child: _isImportingWallet
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Import Identity'),
                  ),
                ],
                
                const Spacer(),
                
                // Footer
                Text(
                  'Your identity is secured by blockchain technology',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 