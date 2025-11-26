import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/wallet_provider.dart';
import '../services/secure_storage_service.dart';
import '../services/blockchain_service.dart';
import 'gas_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _secureStorage = SecureStorageService();
  bool _showMnemonic = false;
  String? _mnemonic;

  Future<void> _loadMnemonic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mnemonic = await _secureStorage.getMnemonic(prefs);
      setState(() {
        _mnemonic = mnemonic;
        _showMnemonic = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recovery phrase: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAddress = ref.watch(walletAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        children: [
          // Identity Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Identity Address
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text('Identity Address'),
                    subtitle: Text(
                      walletAddress ?? 'Not connected',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    trailing: walletAddress != null
                        ? IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyToClipboard(walletAddress!),
                            tooltip: 'Copy address',
                          )
                        : null,
                  ),
                  
                  const Divider(),
                  
                  // Export Recovery Phrase
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('Recovery Phrase'),
                    subtitle: const Text('Export your recovery phrase to backup your identity'),
                    trailing: _showMnemonic
                        ? IconButton(
                            icon: const Icon(Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _showMnemonic = false;
                                _mnemonic = null;
                              });
                            },
                            tooltip: 'Hide recovery phrase',
                          )
                        : IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: _loadMnemonic,
                            tooltip: 'Show recovery phrase',
                          ),
                  ),
                  
                  // Recovery Phrase Display
                  if (_showMnemonic && _mnemonic != null) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: AppConstants.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                        border: Border.all(color: AppConstants.warningColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Keep this secret!',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppConstants.warningColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            _mnemonic!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _copyToClipboard(_mnemonic!),
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Danger Zone
          Card(
            color: AppConstants.errorColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppConstants.errorColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: AppConstants.errorColor,
                    ),
                    title: Text(
                      'Disconnect Identity',
                      style: TextStyle(color: AppConstants.errorColor),
                    ),
                    subtitle: const Text('This will disconnect your identity from this device. You can reconnect using your recovery phrase.'),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.arrow_forward,
                        color: AppConstants.errorColor,
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Disconnect Identity?'),
                            content: const Text(
                              'Are you sure you want to disconnect your identity? '
                              'You will need your recovery phrase to reconnect.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppConstants.errorColor,
                                ),
                                child: const Text('Disconnect'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true && mounted) {
                          await ref.read(walletProvider.notifier).disconnectWallet();
                          // Navigation will be handled by AppRouter
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

