import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';

/// Helper class for setting up Hive encryption
/// Encrypts sensitive data at rest using AES cipher
class HiveEncryptionHelper {
  static const String _encryptionKeyName = 'hive_encryption_key';

  /// Get encryption cipher for sensitive data
  /// Returns null if encryption is not available or disabled
  static Future<HiveAesCipher?> getEncryptionCipher() async {
    try {
      // For now, encryption is disabled (returns null)
      // To enable encryption:
      // 1. Generate and store encryption key in secure storage
      // 2. Uncomment the code below
      // 3. Use cipher when opening boxes: await Hive.openBox<Map>('boxName', encryptionCipher: cipher)

      // Optional: Implement encryption with secure key storage
      // final secureStorage = SecureStorageApi();
      // let encryptionKey = await secureStorage.read(key: _encryptionKeyName);
      //
      // if (encryptionKey == null) {
      //   // Generate new encryption key
      //   encryptionKey = _generateEncryptionKey();
      //   await secureStorage.write(key: _encryptionKeyName, value: encryptionKey);
      //   await LogUtils.info('Generated new Hive encryption key');
      // }
      //
      // // Create cipher from key
      // final keyBytes = base64Decode(encryptionKey);
      // return HiveAesCipher(keyBytes);

      return null;
    } catch (e) {
      await LogUtils.error('Error getting encryption cipher', e);
      return null;
    }
  }

  /// Initialize encryption for sensitive boxes
  /// Call this from main.dart after Hive.initFlutter()
  static Future<void> initializeEncryption() async {
    try {
      // Optional: Set up encryption for sensitive data
      // Example usage:
      // final cipher = await getEncryptionCipher();
      // await Hive.openBox<Map>('sensitive_customers', encryptionCipher: cipher);

      await LogUtils.info('Hive encryption ready (currently disabled)');
    } catch (e) {
      await LogUtils.error('Error initializing Hive encryption', e);
    }
  }

  /// Generate a random AES encryption key
  /// Returns base64-encoded key string
  static String _generateEncryptionKey() {
    // Generate 32-byte (256-bit) key for AES-256
    final key = Hive.generateSecureKey();
    return base64Encode(key);
  }

  /// Disable encryption by removing stored key
  /// WARNING: Only use if migrating away from encrypted storage
  static Future<void> disableEncryption() async {
    try {
      final secureStorage = SecureStorageApi();
      await secureStorage.delete(key: _encryptionKeyName);
      await LogUtils.info('Hive encryption key removed');
    } catch (e) {
      await LogUtils.error('Error disabling encryption', e);
    }
  }

  /// Rotate encryption key (generate new key and re-encrypt data)
  /// WARNING: This is a complex operation, ensure backup before proceeding
  static Future<void> rotateEncryptionKey() async {
    try {
      await LogUtils.warning('Starting Hive encryption key rotation...');

      // 1. Generate new key
      final newKey = _generateEncryptionKey();

      // 2. Store new key
      final secureStorage = SecureStorageApi();
      await secureStorage.write(_encryptionKeyName, newKey);

      // 3. Clear old cache (data will be re-synced from server)
      // Note: In production, you'd want more sophisticated re-encryption logic
      await Hive.deleteBoxFromDisk('customers');
      await Hive.deleteBoxFromDisk('items');
      // ... etc for all boxes

      await LogUtils.info('Hive encryption key rotation complete');
    } catch (e) {
      await LogUtils.error('Error rotating encryption key', e);
      rethrow;
    }
  }
}
