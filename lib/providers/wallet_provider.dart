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
    // Wrap in unawaited to prevent blocking, but catch errors to prevent crashes
    _restoreWalletAsync().catchError((error, stack) {
      debugPrint('WalletNotifier: Error in async wallet restoration: $error');
      debugPrint('WalletNotifier: Stack: $stack');
      // Don't crash the app - just log the error
      // The wallet will remain disconnected if restoration fails
    });
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
    try {
      // Ensure BlockchainService is initialized before attempting restoration
      // Wrap in try-catch to handle initialization errors gracefully
      try {
        await blockchainService.initialize();
      } catch (e) {
        debugPrint('WalletNotifier: BlockchainService initialization failed: $e');
        // Continue anyway - might be a network issue, wallet can still be restored
      }
      
      // First, check if mnemonic is stored
      String? storedMnemonic;
      try {
        storedMnemonic = await _secureStorage.getMnemonic(_prefs);
      } catch (e) {
        debugPrint('WalletNotifier: Error reading mnemonic from secure storage: $e');
        // Continue to check for private key
      }
      
      if (storedMnemonic != null && storedMnemonic.isNotEmpty) {
        try {
          // Restore wallet from stored mnemonic
          debugPrint('WalletNotifier: Restoring wallet from stored mnemonic');
          await blockchainService.importWallet(storedMnemonic);
          final walletAddress = blockchainService.walletAddress;
          
          if (walletAddress != null) {
            // Verify the address matches what we have stored
            final storedAddress = _prefs.getString(AppConstants.walletDataKey);
            if (storedAddress != walletAddress) {
              debugPrint('WalletNotifier: Stored address mismatch, updating stored address');
            }
            // Store wallet address for reference
            await _prefs.setString(AppConstants.walletDataKey, walletAddress);
            state = true;
            debugPrint('WalletNotifier: Wallet restored from mnemonic: $walletAddress');
            return;
          }
        } catch (e) {
          debugPrint('WalletNotifier: Error restoring from mnemonic: $e');
          // Continue to try private key
        }
      }
      
      // If no mnemonic, check for stored private key
      String? storedPrivateKey;
      try {
        storedPrivateKey = await _secureStorage.getPrivateKey(_prefs);
      } catch (e) {
        debugPrint('WalletNotifier: Error reading private key from secure storage: $e');
      }
      
      if (storedPrivateKey != null && storedPrivateKey.isNotEmpty) {
        try {
          // Restore wallet from stored private key
          debugPrint('WalletNotifier: Restoring wallet from stored private key');
          await blockchainService.importWalletFromPrivateKey(storedPrivateKey);
          final walletAddress = blockchainService.walletAddress;
          
          if (walletAddress != null) {
            // Verify the address matches what we have stored
            final storedAddress = _prefs.getString(AppConstants.walletDataKey);
            if (storedAddress != walletAddress) {
              debugPrint('WalletNotifier: Stored address mismatch, updating stored address');
            }
            // Store wallet address for reference
            await _prefs.setString(AppConstants.walletDataKey, walletAddress);
            state = true;
            debugPrint('WalletNotifier: Wallet restored from private key: $walletAddress');
            return;
          }
        } catch (e) {
          debugPrint('WalletNotifier: Error restoring from private key: $e');
        }
      }
      
      // No stored credentials found - check if wallet is already connected in BlockchainService
      // (this handles the case where wallet was connected in current session but not persisted)
      try {
        if (blockchainService.isWalletConnected) {
          final walletAddress = blockchainService.walletAddress;
          if (walletAddress != null) {
            await _prefs.setString(AppConstants.walletDataKey, walletAddress);
            state = true;
            debugPrint('WalletNotifier: Wallet already connected in BlockchainService: $walletAddress');
            return;
          }
        }
      } catch (e) {
        debugPrint('WalletNotifier: Error checking BlockchainService connection: $e');
      }
      
      // No stored credentials found and no active connection
      debugPrint('WalletNotifier: No stored wallet credentials found');
      state = false;
    } catch (e, stack) {
      debugPrint('WalletNotifier: Unexpected error in wallet restoration: $e');
      debugPrint('WalletNotifier: Stack: $stack');
      // Don't crash - just set state to false
      state = false;
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
        
        // Trigger avatar sync from blockchain when wallet connects
        // This will load any existing avatars that exist on-chain but not in local storage
        try {
          // Get the avatar provider and sync
          // Note: We can't directly access ref here, so we'll let the AppRouter handle this
          // by watching the wallet provider and triggering sync
          debugPrint('WalletNotifier.connectWallet: Wallet connected, avatar sync should be triggered by AppRouter');
        } catch (e) {
          debugPrint('WalletNotifier.connectWallet: Error triggering avatar sync: $e');
        }
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

  /// Connect wallet using private key
  Future<void> connectWalletWithPrivateKey(String privateKey) async {
    try {
      debugPrint('WalletNotifier.connectWalletWithPrivateKey: Importing wallet with private key');
      
      // Import wallet from private key
      await blockchainService.importWalletFromPrivateKey(privateKey);
      
      final walletAddress = blockchainService.walletAddress;
      debugPrint('WalletNotifier.connectWalletWithPrivateKey: walletAddress = $walletAddress');
      debugPrint('WalletNotifier.connectWalletWithPrivateKey: isWalletConnected = ${blockchainService.isWalletConnected}');
      
      if (walletAddress != null) {
        // Store private key encrypted for future restoration
        await _secureStorage.storePrivateKey(privateKey, _prefs);
        // Store wallet address for reference
        await _prefs.setString(AppConstants.walletDataKey, walletAddress);
        // Update state to trigger AppRouter rebuild
        state = true;
        debugPrint('WalletNotifier.connectWalletWithPrivateKey: Wallet connected and stored, state set to true');
      } else {
        state = false;
        debugPrint('WalletNotifier.connectWalletWithPrivateKey: No wallet address, state set to false');
      }
    } catch (e) {
      debugPrint('Error connecting wallet with private key: $e');
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
      await _secureStorage.removePrivateKey(_prefs);
      // Note: BlockchainService doesn't have a disconnect method
      // The wallet state is cleared from preferences and secure storage
      state = false;
      debugPrint('Wallet disconnected and all credentials removed');
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

