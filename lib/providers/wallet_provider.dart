import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/blockchain_service.dart';
import '../services/secure_storage_service.dart';
import '../services/faucet_service.dart';
import '../constants/app_constants.dart';
import 'avatar_provider.dart';

/// Provider for managing wallet connection state
class WalletNotifier extends StateNotifier<bool> {
  // Lazy-initialize services to avoid circular dependencies during provider creation
  BlockchainService? _blockchainService;
  BlockchainService get blockchainService => _blockchainService ??= BlockchainService();
  
  final SecureStorageService _secureStorage = SecureStorageService();
  final FaucetService _faucetService = FaucetService();
  final SharedPreferences _prefs;
  bool _isInitialized = false;

  WalletNotifier(this._prefs) : super(_loadInitialState(_prefs)) {
    // State is initialized directly in super() to prevent rebuild loops
    // Mark as initialized after synchronous load
    _isInitialized = true;
    // Then do async restoration if needed (after constructor completes)
    _restoreWalletAsync();
  }

  /// Load initial state synchronously from SharedPreferences
  /// Avoid creating BlockchainService instances here to prevent circular dependencies
  static bool _loadInitialState(SharedPreferences prefs) {
    try {
      // Simply check if wallet address is stored in SharedPreferences
      // The actual wallet restoration will happen asynchronously in _restoreWallet
      final walletAddress = prefs.getString(AppConstants.walletDataKey);
      if (walletAddress != null && walletAddress.isNotEmpty) {
        // If an address is stored, assume connected for initial UI rendering
        // The actual connection will be verified asynchronously
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error loading initial wallet state: $e');
      return false;
    }
  }

  /// Restore wallet from encrypted storage on app start (async, called after constructor)
  Future<void> _restoreWalletAsync() async {
    if (state) return; // Already connected from sync load
    
    try {
      // Check if mnemonic is stored
      final storedMnemonic = await _secureStorage.getMnemonic(_prefs);
      
      if (storedMnemonic != null && storedMnemonic.isNotEmpty) {
        // Restore wallet from stored mnemonic
        await blockchainService.importWallet(storedMnemonic);
        final walletAddress = blockchainService.walletAddress;
        
        if (walletAddress != null) {
          // Store wallet address for reference
          await _prefs.setString(AppConstants.walletDataKey, walletAddress);
          if (!state) { // Only update if not already true from sync load
            state = true;
            debugPrint('Wallet restored from secure storage');
          }
        } else if (!state) {
          state = false;
        }
      } else if (!state) {
        // No stored mnemonic, check if blockchain service has wallet (for current session)
        final isConnected = blockchainService.isWalletConnected;
        state = isConnected;
        if (isConnected) {
          final address = blockchainService.walletAddress;
          if (address != null) {
            await _prefs.setString(AppConstants.walletDataKey, address);
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring wallet asynchronously: $e');
      if (!state) {
        state = false;
      }
    }
  }

  Future<void> connectWallet(String? mnemonic) async {
    try {
      debugPrint('WalletNotifier.connectWallet: mnemonic provided = ${mnemonic != null && mnemonic.isNotEmpty}');
      
      // If mnemonic provided, import wallet and store it securely
      if (mnemonic != null && mnemonic.isNotEmpty) {
        debugPrint('WalletNotifier.connectWallet: Importing wallet with mnemonic');
        await blockchainService.importWallet(mnemonic);
        // Store mnemonic encrypted for future restoration
        await _secureStorage.storeMnemonic(mnemonic, _prefs);
      }
      // Otherwise, assume wallet is already created/imported in blockchain service
      // If wallet was just created, we need to get the mnemonic from blockchain service
      // For now, we'll store it when user confirms they've saved it
      
      // Force a small delay to ensure wallet is fully set in singleton if it was just created
      if (mnemonic == null || mnemonic.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      final walletAddress = blockchainService.walletAddress;
      debugPrint('WalletNotifier.connectWallet: walletAddress = $walletAddress');
      debugPrint('WalletNotifier.connectWallet: isWalletConnected = ${blockchainService.isWalletConnected}');
      
      if (walletAddress != null) {
        // Store wallet address for reference
        await _prefs.setString(AppConstants.walletDataKey, walletAddress);
        // Update state to trigger AppRouter rebuild
        state = true;
        debugPrint('WalletNotifier.connectWallet: Wallet connected, state set to true');
      } else {
        state = false;
        debugPrint('WalletNotifier.connectWallet: No wallet address, state set to false');
      }
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
      state = false;
      rethrow;
    }
  }

  /// Store mnemonic for wallet that was just created
  Future<void> storeCreatedWalletMnemonic(String mnemonic) async {
    try {
      await _secureStorage.storeMnemonic(mnemonic, _prefs);
      debugPrint('Wallet mnemonic stored securely');
    } catch (e) {
      debugPrint('Error storing wallet mnemonic: $e');
      rethrow;
    }
  }

  Future<void> disconnectWallet() async {
    try {
      await _prefs.remove(AppConstants.walletDataKey);
      await _secureStorage.removeMnemonic(_prefs);
      // Note: BlockchainService doesn't have a disconnect method
      // The wallet state is cleared from preferences and secure storage
      state = false;
    } catch (e) {
      debugPrint('Error disconnecting wallet: $e');
    }
  }

  String? get walletAddress => blockchainService.walletAddress;
  bool get isConnected => state;
}

// Provider
// Use ref.read instead of ref.watch to prevent recreation loops
final walletProvider = StateNotifierProvider<WalletNotifier, bool>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return WalletNotifier(prefs);
});

// Derived providers
final walletAddressProvider = Provider<String?>((ref) {
  final notifier = ref.watch(walletProvider.notifier);
  return notifier.walletAddress;
});

final isWalletConnectedProvider = Provider<bool>((ref) {
  return ref.watch(walletProvider);
});

