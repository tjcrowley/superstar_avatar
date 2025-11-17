import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/blockchain_service.dart';
import '../services/secure_storage_service.dart';
import '../constants/app_constants.dart';
import 'avatar_provider.dart';

/// Provider for managing wallet connection state
class WalletNotifier extends StateNotifier<bool> {
  final BlockchainService _blockchainService = BlockchainService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final SharedPreferences _prefs;

  WalletNotifier(this._prefs) : super(false) {
    _restoreWallet();
  }

  /// Restore wallet from encrypted storage on app start
  Future<void> _restoreWallet() async {
    try {
      // Check if mnemonic is stored
      final storedMnemonic = await _secureStorage.getMnemonic(_prefs);
      
      if (storedMnemonic != null && storedMnemonic.isNotEmpty) {
        // Restore wallet from stored mnemonic
        await _blockchainService.importWallet(storedMnemonic);
        final walletAddress = _blockchainService.walletAddress;
        
        if (walletAddress != null) {
          // Store wallet address for reference
          await _prefs.setString(AppConstants.walletDataKey, walletAddress);
          state = true;
          debugPrint('Wallet restored from secure storage');
        } else {
          state = false;
        }
      } else {
        // No stored wallet, check if blockchain service has wallet (for current session)
        final isConnected = _blockchainService.isWalletConnected;
        state = isConnected;
        
        if (isConnected) {
          final address = _blockchainService.walletAddress;
          if (address != null) {
            await _prefs.setString(AppConstants.walletDataKey, address);
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring wallet: $e');
      state = false;
    }
  }

  Future<void> connectWallet(String? mnemonic) async {
    try {
      // If mnemonic provided, import wallet and store it securely
      if (mnemonic != null && mnemonic.isNotEmpty) {
        await _blockchainService.importWallet(mnemonic);
        // Store mnemonic encrypted for future restoration
        await _secureStorage.storeMnemonic(mnemonic, _prefs);
      }
      // Otherwise, assume wallet is already created/imported in blockchain service
      // If wallet was just created, we need to get the mnemonic from blockchain service
      // For now, we'll store it when user confirms they've saved it
      
      final walletAddress = _blockchainService.walletAddress;
      if (walletAddress != null) {
        // Store wallet address for reference
        await _prefs.setString(AppConstants.walletDataKey, walletAddress);
        // Update state to trigger AppRouter rebuild
        state = true;
      } else {
        state = false;
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

  String? get walletAddress => _blockchainService.walletAddress;
  bool get isConnected => state;
}

// Provider
final walletProvider = StateNotifierProvider<WalletNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    return WalletNotifier(SharedPreferences.getInstance() as SharedPreferences);
  }
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

