import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../services/blockchain_service.dart';
import '../providers/wallet_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/secure_text_field.dart';

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

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreatingWallet = true;
    });

    try {
      final blockchainService = BlockchainService();
      final mnemonic = await blockchainService.createWallet();
      final walletAddress = blockchainService.walletAddress;

      // Connect wallet via provider (without storing mnemonic yet - user needs to confirm they saved it)
      await ref.read(walletProvider.notifier).connectWallet(null);

      setState(() {
        _generatedMnemonic = mnemonic;
        _walletAddress = walletAddress;
        _showMnemonic = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet created successfully! Please save your recovery phrase.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create wallet: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingWallet = false;
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
      final blockchainService = BlockchainService();
      await blockchainService.importWallet(mnemonic);
      final walletAddress = blockchainService.walletAddress;

      // Connect wallet via provider to trigger AppRouter rebuild
      await ref.read(walletProvider.notifier).connectWallet(mnemonic);

      setState(() {
        _walletAddress = walletAddress;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet imported successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import wallet: $e'),
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
      
      // Ensure wallet provider state is updated to trigger AppRouter rebuild
      await ref.read(walletProvider.notifier).connectWallet(null);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet saved! Your wallet will be restored automatically on next launch.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save wallet: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch wallet provider to detect when wallet is connected
    final isWalletConnected = ref.watch(isWalletConnectedProvider);
    
    // If wallet is connected, show loading while AppRouter navigates
    if (isWalletConnected && _walletAddress != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppConstants.spacingL),
                Text(
                  'Wallet connected! Setting up your experience...',
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
                    Icons.account_balance_wallet,
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
                  'Connect your wallet to start your journey',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.spacingXL),

                // Wallet Address Display (only show if wallet is connected but not yet navigated)
                if (_walletAddress != null && !_showMnemonic && !isWalletConnected) ...[
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
                          'Wallet Connected',
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
                          'Write this down and keep it safe. You\'ll need it to recover your wallet.',
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
                        : const Text('Create New Wallet'),
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
                    child: const Text('Import Existing Wallet'),
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
                        : const Text('Import Wallet'),
                  ),
                ],
                
                const Spacer(),
                
                // Footer
                Text(
                  'Your wallet is secured by blockchain technology',
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