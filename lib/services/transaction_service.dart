import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import '../constants/app_constants.dart';
import 'blockchain_service.dart';
import 'account_abstraction_service.dart';
import 'admin_service.dart';

/// Service for handling all blockchain transactions with paymaster support
/// Routes transactions through account abstraction when possible
class TransactionService {
  // Lazy-initialize services to avoid circular dependencies
  BlockchainService? _blockchainService;
  BlockchainService get blockchainService => _blockchainService ??= BlockchainService();
  
  final AccountAbstractionService _accountAbstraction = AccountAbstractionService();
  final AdminService _adminService = AdminService();

  /// Check if paymaster sponsorship is enabled for all transactions
  Future<bool> _isPaymasterEnabled() async {
    try {
      // Check if all transactions sponsorship is enabled (preferred)
      final allTransactionsEnabled = await _adminService.isAllTransactionsSponsored();
      if (allTransactionsEnabled) return true;
      
      // Fall back to avatar creation sponsorship
      return await _adminService.isAvatarCreationSponsored();
    } catch (e) {
      debugPrint('Could not check paymaster status: $e');
      return false;
    }
  }

  /// Check if user is whitelisted for gasless transactions
  Future<bool> _isUserWhitelisted() async {
    try {
      if (!blockchainService.isWalletConnected) return false;
      final paymentInfo = await _adminService.getUserPaymentInfo(
        blockchainService.walletAddress!,
      );
      return paymentInfo['hasWhitelist'] as bool? ?? false;
    } catch (e) {
      debugPrint('Could not check whitelist status: $e');
      return false;
    }
  }

  /// Ensure user is whitelisted for gasless transactions
  Future<void> _ensureUserWhitelisted() async {
    try {
      final isEnabled = await _isPaymasterEnabled();
      if (!isEnabled) return;

      final isWhitelisted = await _isUserWhitelisted();
      if (isWhitelisted) return;

      // Try to whitelist user for all transactions first (if enabled)
      try {
        final allTransactionsEnabled = await _adminService.isAllTransactionsSponsored();
        if (allTransactionsEnabled) {
          await _adminService.whitelistUserForAllTransactions(
            blockchainService.walletAddress!,
          );
          debugPrint('User whitelisted for all gasless transactions');
          return;
        }
      } catch (e) {
        debugPrint('Could not whitelist for all transactions: $e');
      }

      // Fall back to avatar creation whitelisting
      await _adminService.whitelistUserForAvatarCreation(
        blockchainService.walletAddress!,
      );
      debugPrint('User whitelisted for gasless transactions');
    } catch (e) {
      debugPrint('Could not whitelist user (may already be whitelisted): $e');
      // Continue anyway - user might already be whitelisted
    }
  }

  /// Send a transaction, routing through paymaster if available
  /// 
  /// This function:
  /// 1. Tries to use account abstraction (ERC-4337) if bundler is configured
  /// 2. Falls back to regular transaction if account abstraction fails
  /// 3. Ensures user is whitelisted for gasless transactions
  Future<String> sendTransaction({
    required DeployedContract contract,
    required ContractFunction function,
    required List<dynamic> parameters,
    EtherAmount? value,
    bool useAccountAbstraction = true,
  }) async {
    if (!blockchainService.isWalletConnected) {
      throw Exception('Wallet not connected');
    }

    // Ensure user is whitelisted for gasless transactions
    await _ensureUserWhitelisted();

    // Try account abstraction first if enabled and bundler is configured
    if (useAccountAbstraction) {
      try {
        return await _sendViaAccountAbstraction(
          contract: contract,
          function: function,
          parameters: parameters,
          value: value,
        );
      } catch (e) {
        debugPrint('Account abstraction failed, falling back to regular transaction: $e');
        // Check if it's a stack overflow or recursion error
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('stack overflow') || 
            errorString.contains('stackoverflow') ||
            errorString.contains('recursion')) {
          debugPrint('Stack overflow detected in account abstraction - using regular transaction');
        }
        // Fall through to regular transaction
      }
    }

    // Fall back to regular transaction
    return await _sendRegularTransaction(
      contract: contract,
      function: function,
      parameters: parameters,
      value: value,
    );
  }

  /// Send transaction via account abstraction (ERC-4337)
  Future<String> _sendViaAccountAbstraction({
    required DeployedContract contract,
    required ContractFunction function,
    required List<dynamic> parameters,
    EtherAmount? value,
  }) async {
    // Check if bundler is configured
    final bundlerUrl = AppConstants.bundlerRpcUrl;
    if (bundlerUrl.contains('YOUR_API_KEY') || bundlerUrl.contains('example.com')) {
      throw Exception('Bundler not configured');
    }

    // Check if account exists
    final hasAccount = await _accountAbstraction.hasAccount(
      blockchainService.walletAddress!,
    );

    if (!hasAccount) {
      // Account doesn't exist - it will be created via initCode in the UserOp
      // This allows account creation to be sponsored by the paymaster (gasless!)
      debugPrint('Account does not exist - will be created via initCode in UserOp (gasless via paymaster)');
    }

    // Encode function call
    final callDataBytes = function.encodeCall(parameters);
    // Convert Uint8List to hex string
    final callData = '0x${callDataBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}';
    final contractAddress = contract.address.hex;

    // Get paymaster data
    final paymasterData = await _accountAbstraction.getPaymasterData();

    // Create user operation
    final userOp = await _accountAbstraction.createUserOperation(
      to: contractAddress,
      data: callData,
      value: value?.getInWei,
      paymasterAndData: paymasterData,
    );

    // Send user operation
    final userOpHash = await _accountAbstraction.sendUserOperation(userOp);
    debugPrint('Transaction sent via account abstraction: $userOpHash');
    return userOpHash;
  }

  /// Send regular transaction (fallback)
  Future<String> _sendRegularTransaction({
    required DeployedContract contract,
    required ContractFunction function,
    required List<dynamic> parameters,
    EtherAmount? value,
  }) async {
    final transaction = Transaction.callContract(
      contract: contract,
      function: function,
      parameters: parameters,
      value: value,
    );

    final txHash = await blockchainService.client.sendTransaction(
      blockchainService.credentials,
      transaction,
      chainId: int.parse(AppConstants.polygonChainId),
    );

    return txHash;
  }
}

