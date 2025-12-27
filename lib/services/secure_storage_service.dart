import 'package:flutter/foundation.dart' show debugPrint;
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for securely storing and retrieving sensitive data like mnemonics
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const String _encryptionKeyKey = 'wallet_encryption_key';
  static const String _encryptedMnemonicKey = 'encrypted_wallet_mnemonic';
  static const String _encryptedPrivateKeyKey = 'encrypted_wallet_private_key';

  /// Get or create encryption key
  Future<Key> _getEncryptionKey(SharedPreferences prefs) async {
    String? keyString = prefs.getString(_encryptionKeyKey);
    
    if (keyString == null || keyString.isEmpty) {
      // Generate a new key
      final key = Key.fromSecureRandom(32);
      keyString = key.base64;
      await prefs.setString(_encryptionKeyKey, keyString);
    }
    
    return Key.fromBase64(keyString);
  }

  /// Encrypt and store mnemonic
  Future<void> storeMnemonic(String mnemonic, SharedPreferences prefs) async {
    try {
      final key = await _getEncryptionKey(prefs);
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key));
      
      final encrypted = encrypter.encrypt(mnemonic, iv: iv);
      
      // Store encrypted mnemonic and IV
      await prefs.setString(_encryptedMnemonicKey, encrypted.base64);
      await prefs.setString('${_encryptedMnemonicKey}_iv', iv.base64);
    } catch (e) {
      throw Exception('Failed to store mnemonic securely: $e');
    }
  }

  /// Retrieve and decrypt mnemonic
  Future<String?> getMnemonic(SharedPreferences prefs) async {
    try {
      final encryptedBase64 = prefs.getString(_encryptedMnemonicKey);
      final ivBase64 = prefs.getString('${_encryptedMnemonicKey}_iv');
      
      if (encryptedBase64 == null || ivBase64 == null) {
        return null;
      }
      
      if (encryptedBase64.isEmpty || ivBase64.isEmpty) {
        return null;
      }
      
      final key = await _getEncryptionKey(prefs);
      final iv = IV.fromBase64(ivBase64);
      final encrypter = Encrypter(AES(key));
      
      final encrypted = Encrypted.fromBase64(encryptedBase64);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      // Validate decrypted mnemonic is not empty
      if (decrypted.isEmpty) {
        return null;
      }
      
      return decrypted;
    } catch (e) {
      // If decryption fails, return null (wallet needs to be re-imported)
      // Log error but don't crash
      debugPrint('SecureStorageService: Error decrypting mnemonic: $e');
      return null;
    }
  }

  /// Remove stored mnemonic
  Future<void> removeMnemonic(SharedPreferences prefs) async {
    await prefs.remove(_encryptedMnemonicKey);
    await prefs.remove('${_encryptedMnemonicKey}_iv');
  }

  /// Check if mnemonic is stored
  Future<bool> hasStoredMnemonic(SharedPreferences prefs) async {
    final encryptedBase64 = prefs.getString(_encryptedMnemonicKey);
    return encryptedBase64 != null && encryptedBase64.isNotEmpty;
  }

  /// Encrypt and store private key
  Future<void> storePrivateKey(String privateKey, SharedPreferences prefs) async {
    try {
      final key = await _getEncryptionKey(prefs);
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key));
      
      final encrypted = encrypter.encrypt(privateKey, iv: iv);
      
      // Store encrypted private key and IV
      await prefs.setString(_encryptedPrivateKeyKey, encrypted.base64);
      await prefs.setString('${_encryptedPrivateKeyKey}_iv', iv.base64);
    } catch (e) {
      throw Exception('Failed to store private key securely: $e');
    }
  }

  /// Retrieve and decrypt private key
  Future<String?> getPrivateKey(SharedPreferences prefs) async {
    try {
      final encryptedBase64 = prefs.getString(_encryptedPrivateKeyKey);
      final ivBase64 = prefs.getString('${_encryptedPrivateKeyKey}_iv');
      
      if (encryptedBase64 == null || ivBase64 == null) {
        return null;
      }
      
      if (encryptedBase64.isEmpty || ivBase64.isEmpty) {
        return null;
      }
      
      final key = await _getEncryptionKey(prefs);
      final iv = IV.fromBase64(ivBase64);
      final encrypter = Encrypter(AES(key));
      
      final encrypted = Encrypted.fromBase64(encryptedBase64);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      // Validate decrypted private key is not empty
      if (decrypted.isEmpty) {
        return null;
      }
      
      return decrypted;
    } catch (e) {
      // If decryption fails, return null (wallet needs to be re-imported)
      // Log error but don't crash
      debugPrint('SecureStorageService: Error decrypting private key: $e');
      return null;
    }
  }

  /// Remove stored private key
  Future<void> removePrivateKey(SharedPreferences prefs) async {
    await prefs.remove(_encryptedPrivateKeyKey);
    await prefs.remove('${_encryptedPrivateKeyKey}_iv');
  }

  /// Check if private key is stored
  Future<bool> hasStoredPrivateKey(SharedPreferences prefs) async {
    final encryptedBase64 = prefs.getString(_encryptedPrivateKeyKey);
    return encryptedBase64 != null && encryptedBase64.isNotEmpty;
  }
}

