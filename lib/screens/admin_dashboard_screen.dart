import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';
import '../constants/app_constants.dart';
import '../services/admin_service.dart';
import '../services/goldfire_token_service.dart';
import '../services/blockchain_service.dart';
import '../widgets/gradient_button.dart';

/// Admin dashboard screen with full control over system
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final GoldfireTokenService _goldfireTokenService = GoldfireTokenService();
  final BlockchainService _blockchainService = BlockchainService();
  
  bool _isLoading = true;
  bool _isAdmin = false;
  BigInt _paymasterBalance = BigInt.zero;
  List<String> _admins = [];
  String _mintToAddress = '';
  String _mintAmount = '';
  String _withdrawAmount = '';
  
  // Event Producer Registration
  String _producerId = '';
  String _producerAvatarId = '';
  String _producerName = '';
  String _producerDescription = '';
  String _producerWalletAddress = '';
  String _producerMetadata = '';
  
  // Admin Management
  String _newAdminAddress = '';
  bool _isAddingAdmin = false;
  bool _isRemovingAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAdmin = await _adminService.isAdmin();
      if (!isAdmin) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Admin privileges required.'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }

      final paymasterBalance = await _adminService.getPaymasterBalance();
      final admins = await _adminService.getAllAdmins();

      setState(() {
        _isAdmin = true;
        _paymasterBalance = paymasterBalance;
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _mintTokens() async {
    if (_mintToAddress.isEmpty || _mintAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter address and amount'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    try {
      final amount = await _goldfireTokenService.parseAmount(_mintAmount);
      final txHash = await _adminService.mintGoldfireTokens(_mintToAddress, amount);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tokens minted! Transaction: $txHash'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        setState(() {
          _mintToAddress = '';
          _mintAmount = '';
        });
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

  Future<void> _depositToPaymaster() async {
    try {
      // This would require sending native tokens
      // For now, show instructions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use depositToPaymaster with native tokens'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
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

  Future<void> _withdrawFromPaymaster() async {
    if (_withdrawAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter amount'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    try {
      final amount = BigInt.parse(_withdrawAmount);
      final txHash = await _adminService.withdrawFromPaymaster(amount);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal submitted: $txHash'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        await _checkAdminStatus(); // Refresh balance
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

  Future<void> _registerEventProducer() async {
    if (_producerId.isEmpty || 
        _producerAvatarId.isEmpty || 
        _producerName.isEmpty || 
        _producerWalletAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    try {
      final txHash = await _adminService.registerEventProducer(
        producerId: _producerId,
        avatarId: _producerAvatarId,
        name: _producerName,
        description: _producerDescription,
        walletAddress: _producerWalletAddress,
        metadata: _producerMetadata,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event producer registered! Transaction: $txHash'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _producerId = '';
          _producerAvatarId = '';
          _producerName = '';
          _producerDescription = '';
          _producerWalletAddress = '';
          _producerMetadata = '';
        });
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

  Future<void> _addAdmin() async {
    if (_newAdminAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an admin address'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    // Basic address validation
    if (!_newAdminAddress.startsWith('0x') || _newAdminAddress.length != 42) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid wallet address format'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    // Check if already an admin
    if (_admins.contains(_newAdminAddress)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This address is already an admin'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isAddingAdmin = true;
    });

    try {
      final txHash = await _adminService.addAdmin(_newAdminAddress);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin added! Transaction: $txHash'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _newAdminAddress = '';
        });
        // Refresh admin list
        await _checkAdminStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding admin: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingAdmin = false;
        });
      }
    }
  }

  Future<void> _removeAdmin(String adminAddress) async {
    // Get current wallet address to prevent removing yourself
    final currentAddress = _blockchainService.walletAddress;
    if (currentAddress != null && adminAddress.toLowerCase() == currentAddress.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot remove yourself as admin'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Are you sure you want to remove this admin?\n\n$adminAddress'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRemovingAdmin = true;
    });

    try {
      final txHash = await _adminService.removeAdmin(adminAddress);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin removed! Transaction: $txHash'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
        // Refresh admin list
        await _checkAdminStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing admin: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRemovingAdmin = false;
        });
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

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Paymaster Balance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paymaster Balance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<BigInt>(
                      future: _adminService.getPaymasterBalance(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final balance = snapshot.data!;
                          final balanceEth = EtherAmount.fromBigInt(
                            EtherUnit.wei,
                            balance,
                          ).getValueInUnit(EtherUnit.ether);
                          return Text(
                            '${balanceEth.toStringAsFixed(4)} MATIC',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppConstants.primaryColor,
                            ),
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Admin Management Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Admin Management',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add or remove admin addresses. Only contract owner can manage admins.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Admin Wallet Address',
                        hintText: '0x...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_circle),
                      ),
                      onChanged: (value) => _newAdminAddress = value,
                      enabled: !_isAddingAdmin,
                    ),
                    const SizedBox(height: 8),
                    GradientButton(
                      onPressed: _isAddingAdmin ? null : _addAdmin,
                      child: _isAddingAdmin
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Admin'),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Current Admins (${_admins.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_admins.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No admins found',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._admins.map((admin) {
                        final isCurrentUser = _blockchainService.walletAddress?.toLowerCase() == admin.toLowerCase();
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          color: isCurrentUser 
                              ? AppConstants.primaryColor.withOpacity(0.1)
                              : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            title: Text(
                              admin,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            subtitle: isCurrentUser
                                ? const Text(
                                    'You (cannot remove)',
                                    style: TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                            trailing: isCurrentUser
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppConstants.primaryColor,
                                  )
                                : IconButton(
                                    icon: _isRemovingAdmin
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.delete_outline,
                                            color: AppConstants.errorColor,
                                          ),
                                    onPressed: _isRemovingAdmin
                                        ? null
                                        : () => _removeAdmin(admin),
                                    tooltip: 'Remove admin',
                                  ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mint Tokens Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mint Goldfire Tokens',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Recipient Address',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _mintToAddress = value,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Amount (GF)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => _mintAmount = value,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      onPressed: _mintTokens,
                      child: const Text('Mint Tokens'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Paymaster Management Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paymaster Management',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      onPressed: _depositToPaymaster,
                      child: const Text('Deposit to Paymaster'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Withdraw Amount (MATIC)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => _withdrawAmount = value,
                    ),
                    const SizedBox(height: 8),
                    GradientButton(
                      onPressed: _withdrawFromPaymaster,
                      child: const Text('Withdraw from Paymaster'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Event Producer Registration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Register Event Producer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register a new event producer. The producer will be automatically verified.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Producer ID *',
                        hintText: 'e.g., producer-001',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _producerId = value,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Avatar ID *',
                        hintText: 'Avatar ID of the producer',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _producerAvatarId = value,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Producer Name *',
                        hintText: 'Name of the event producer',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _producerName = value,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Producer description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) => _producerDescription = value,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Wallet Address *',
                        hintText: '0x...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _producerWalletAddress = value,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Metadata (JSON)',
                        hintText: 'Optional JSON metadata',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) => _producerMetadata = value,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      onPressed: _registerEventProducer,
                      child: const Text('Register Event Producer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

