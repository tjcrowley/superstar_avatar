import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../providers/avatar_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/gradient_button.dart';
import '../models/power.dart';
import '../services/faucet_service.dart';
import 'wallet_setup_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _faucetService = FaucetService();
  int _currentStep = 0;
  bool _isCreatingAvatar = false;

  @override
  void initState() {
    super.initState();
    // Check if avatar already exists when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final hasAvatar = ref.read(avatarProvider).hasAvatar;
        if (hasAvatar) {
          debugPrint('OnboardingScreen: Avatar already exists, this screen should not be shown');
          // The router should handle this, but as a safeguard, navigate away
          // This should not happen if routing is working correctly
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _createAvatar() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if avatar already exists (safeguard)
    final avatarState = ref.read(avatarProvider);
    if (avatarState.hasAvatar) {
      debugPrint('OnboardingScreen: Avatar already exists, preventing duplicate creation');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar already exists. Redirecting to dashboard...'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        // The router should handle navigation, but wait a moment for state to update
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }
    }

    // Check if wallet is connected
    final isWalletConnected = ref.read(walletProvider);
    if (!isWalletConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect your wallet before creating an avatar'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _isCreatingAvatar = true;
    });

    try {
      await ref.read(avatarProvider.notifier).createPrimaryAvatar(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar created successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        final isInsufficientFunds = errorMessage.toLowerCase().contains('insufficient funds') ||
            errorMessage.toLowerCase().contains('insufficientfunds');
        
        if (isInsufficientFunds) {
          // Show dialog with helpful information
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Insufficient Funds'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You need MATIC to pay for gas fees when creating an avatar. '
                    'Please get testnet MATIC from the faucet.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You need at least 0.01 MATIC to create an avatar.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse(_faucetService.getFaucetUrl(network: 'amoy'));
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Open Faucet'),
                ),
              ],
            ),
          );
        } else {
          // Show regular error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create avatar: ${errorMessage.replaceAll('Exception: ', '')}'),
              backgroundColor: AppConstants.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isCreatingAvatar = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet address copied to clipboard'),
            backgroundColor: AppConstants.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildPowersStep();
      case 2:
        return _buildProfileStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppConstants.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusXXL),
            boxShadow: AppConstants.shadowLarge,
          ),
          child: const Icon(
            Icons.person_add,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Text(
          AppConstants.onboardingTitles[0],
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          AppConstants.onboardingDescriptions[0],
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXL),
        GradientButton(
          onPressed: _nextStep,
          child: const Text('Get Started'),
        ),
      ],
    );
  }

  Widget _buildPowersStep() {
    return Column(
      children: [
        Text(
          AppConstants.onboardingTitles[1],
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          AppConstants.onboardingDescriptions[1],
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingL),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              childAspectRatio: 1.2,
            ),
            itemCount: Power.defaultPowers.length,
            itemBuilder: (context, index) {
              final power = Power.defaultPowers[index];
              final color = AppConstants.powerColors[power.type.toString().split('.').last];
              
              return Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color!.withOpacity(0.1),
                        color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          power.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Text(
                          power.name,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          power.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Row(
          children: [
            OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            ),
            const Spacer(),
            GradientButton(
              onPressed: _nextStep,
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    final isWalletConnected = ref.watch(walletProvider);
    final walletAddress = ref.watch(walletAddressProvider);
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            AppConstants.onboardingTitles[2],
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            AppConstants.onboardingDescriptions[2],
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          // Wallet Connection Status - Small button with copy option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () async {
                  // Show wallet management menu
                  if (mounted) {
                    final action = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Wallet Options'),
                        children: [
                          if (isWalletConnected && walletAddress != null) ...[
                            // Display wallet address with copy button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Wallet Address',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SelectableText(
                                          walletAddress!,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18),
                                        onPressed: () async {
                                          // Copy to clipboard without closing dialog
                                          await Clipboard.setData(ClipboardData(text: walletAddress!));
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Wallet address copied to clipboard'),
                                                backgroundColor: AppConstants.successColor,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        tooltip: 'Copy address',
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        style: IconButton.styleFrom(
                                          minimumSize: const Size(32, 32),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            SimpleDialogOption(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _copyToClipboard(walletAddress!);
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.copy, size: 20),
                                  SizedBox(width: 8),
                                  Text('Copy Wallet Address'),
                                ],
                              ),
                            ),
                          ],
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, 'reconnect'),
                            child: const Row(
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text('Reconnect Wallet'),
                              ],
                            ),
                          ),
                          if (isWalletConnected)
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'disconnect'),
                              child: Row(
                                children: [
                                  const Icon(Icons.link_off, size: 20, color: AppConstants.errorColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Disconnect Wallet',
                                    style: TextStyle(color: AppConstants.errorColor),
                                  ),
                                ],
                              ),
                            ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, 'cancel'),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                    
                    if (action == 'reconnect' && mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WalletSetupScreen(),
                        ),
                      );
                    } else if (action == 'disconnect' && mounted) {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Disconnect Wallet'),
                          content: const Text(
                            'Are you sure you want to disconnect your wallet? '
                            'You will need to reconnect to create an avatar.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.errorColor,
                              ),
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true && mounted) {
                        try {
                          await ref.read(walletProvider.notifier).disconnectWallet();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallet disconnected'),
                                backgroundColor: AppConstants.successColor,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error disconnecting wallet: $e'),
                                backgroundColor: AppConstants.errorColor,
                              ),
                            );
                          }
                        }
                      }
                    }
                  }
                },
                icon: Icon(
                  isWalletConnected ? Icons.check_circle : Icons.error_outline,
                  size: 16,
                  color: isWalletConnected 
                      ? AppConstants.successColor 
                      : AppConstants.errorColor,
                ),
                label: Text(
                  isWalletConnected 
                      ? (walletAddress != null 
                          ? '${walletAddress!.substring(0, 6)}...${walletAddress!.substring(walletAddress!.length - 4)}'
                          : 'Connected')
                      : 'Not Connected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isWalletConnected 
                        ? AppConstants.successColor 
                        : AppConstants.errorColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
              if (isWalletConnected && walletAddress != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyToClipboard(walletAddress!),
                  tooltip: 'Copy wallet address',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          
          // Avatar Image Selection (placeholder) - Made smaller
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusXXL),
              border: Border.all(color: AppConstants.primaryColor),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          TextButton(
            onPressed: () {
              // TODO: Implement avatar image selection
            },
            child: const Text('Choose Avatar Image'),
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Name Input
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Avatar Name',
              hintText: 'Enter your avatar name',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your avatar name';
              }
              if (value.trim().length < AppConstants.minNameLength) {
                return 'Name must be at least ${AppConstants.minNameLength} characters';
              }
              if (value.trim().length > AppConstants.maxNameLength) {
                return 'Name must be less than ${AppConstants.maxNameLength} characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingS),
          
          // Bio Input - Reduced to 2 lines
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio (Optional)',
              hintText: 'Tell us about yourself',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            maxLength: AppConstants.maxBioLength,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (value.trim().length < AppConstants.minBioLength) {
                  return 'Bio must be at least ${AppConstants.minBioLength} characters';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          Row(
            children: [
              OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
              const Spacer(),
              GradientButton(
                onPressed: _isCreatingAvatar ? null : _createAvatar,
                child: _isCreatingAvatar
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Avatar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: AppConstants.textSecondaryColor.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                minHeight: 3,
              ),
              const SizedBox(height: AppConstants.spacingS),
              
              // Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _currentStep 
                          ? AppConstants.primaryColor 
                          : AppConstants.textSecondaryColor.withOpacity(0.3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Content
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 