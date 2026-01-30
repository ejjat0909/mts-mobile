import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/storage/secured_storage_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for SecureStorageApi
/// Access via: ref.read(secureStorageApiProvider) or ref.watch(secureStorageApiProvider)
///
/// Example usage in a ConsumerWidget:
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final storage = ref.read(secureStorageApiProvider);
///     // Use storage...
///   }
/// }
/// ```
///
/// Example usage in a provider:
/// ```dart
/// final myProvider = Provider((ref) {
///   final storage = ref.read(secureStorageApiProvider);
///   return MyService(storage: storage);
/// });
/// ```
final secureStorageApiProvider = Provider<SecureStorageApi>((ref) {
  return SecureStorageApi();
});

/// Legacy global instance - DEPRECATED
/// Use secureStorageApiProvider instead
@Deprecated('Use ref.read(secureStorageApiProvider) instead')
final storage = SecureStorageApi();

/// Secure storage API
class SecureStorageApi {
  static const _boxName = 'secureBox';

  // Generate a 32-byte encryption key
  static Uint8List _generateKey() {
    // Example fixed key (replace with your own securely stored 32-byte key)
    // You can generate one using `base64UrlEncode(Hive.generateSecureKey())`
    const keyString = 'wZz0CjT7X8YpRq3K9uFjSm2Nv5Gh1DsE';
    return Uint8List.fromList(utf8.encode(keyString).take(32).toList());
  }

  static final _encryptionCipher = HiveAesCipher(_generateKey());

  late Box<dynamic> _box;
  bool _initialized = false;

  /// Initialize the Hive box
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        _box = await Hive.openBox(
          _boxName,
          encryptionCipher: _encryptionCipher,
        );
        _initialized = true;
      } catch (e) {
        prints('Error initializing Hive box: $e');
        rethrow;
      }
    }
  }

  /// Read string value from secure storage
  Future<String> read({String? key}) async {
    try {
      await _ensureInitialized();
      final value = _box.get(key ?? 'null');
      if (value == null || value == 'null') {
        return '';
      }
      return value.toString();
    } catch (e) {
      // Handle corrupted encrypted data by clearing the specific key
      if (key != null) {
        try {
          await _ensureInitialized();
          await _box.delete(key);
        } catch (removeError) {
          // If removal fails, ignore and return empty string
        }
      }
      return '';
    }
  }

  /// Write string value to secure storage
  Future<bool> write(String key, String value) async {
    try {
      await _ensureInitialized();
      await _box.put(key, value);
      return true;
    } catch (e) {
      prints('Error writing to secure storage: $e');
      return false;
    }
  }

  /// Read object from secure storage
  Future<dynamic> readObject(String key) async {
    try {
      await _ensureInitialized();
      final value = _box.get(key);
      if (value == null || value == '') {
        return null;
      }
      // If the value is already a Map/List (Hive decoded it), return as-is
      if (value is Map || value is List) {
        return value;
      }
      // Otherwise, treat it as a JSON string and decode
      return json.decode(value.toString());
    } catch (e) {
      // Handle corrupted encrypted data by clearing the specific key
      try {
        await _ensureInitialized();
        await _box.delete(key);
      } catch (removeError) {
        // If removal fails, ignore and return null
      }
      return null;
    }
  }

  /// Save object to secure storage
  Future<void> saveObject(String key, dynamic value) async {
    try {
      await _ensureInitialized();
      // Store as JSON string for consistency with previous implementation
      await _box.put(key, json.encode(value));
    } catch (e) {
      prints('Error saving object to secure storage: $e');
    }
  }

  /// Delete value from secure storage
  Future<bool> delete({required String key}) async {
    try {
      await _ensureInitialized();
      await _box.delete(key);
      return true;
    } catch (e) {
      prints('Error deleting from secure storage: $e');
      return false;
    }
  }

  /// Clear data for a specific key
  Future<bool> clear(String key) async {
    try {
      await _ensureInitialized();
      await _box.delete(key);
      return true;
    } catch (e) {
      prints('Error clearing data for key: $key, $e');
      return false;
    }
  }

  /// Delete all values from secure storage
  // Future<bool> deleteAll() async {
  //   return await _box.clear();
  // }

  /// Save multiple objects to secure storage
  // Future<void> saveMultipleObjects(List<String> keys, dynamic value) async {
  //   for (String key in keys) {
  //     await saveObject(key, value);
  //   }
  // }

  /// Delete token from secure storage
  Future<bool> deleteToken() async {
    prints('🔴 [TRACE] deleteToken() called - deleting access_token');
    try {
      final result = await delete(key: 'access_token');
      prints('✅ Token deleted successfully');
      return result;
    } catch (e) {
      prints('❌ Error in deleteToken: $e');
      return false;
    }
  }

  Future<void> checkAccessToken() async {
    String userAccessToken = await read(key: 'access_token');
    String staffAccessToken = await read(key: 'staff_access_token');
    String licenseKey = await read(key: 'license_key');

    try {
      prints(
        'user token : $userAccessToken\n'
        'staff access token : '
        '$staffAccessToken\n'
        'license key : $licenseKey',
      );
    } catch (e) {
      prints("user token and staff access token are empty");
    }
  }

  /// Reset all sync metadata for all models
  /// This resets the lastSync timestamps by deleting metadata entries
  /// Called during logout to ensure fresh sync on next login
  Future<void> resetAllSyncMetadata() async {
    try {
      await _ensureInitialized();

      prints('🔄 Resetting all sync metadata...');

      // Delete metadata for all models defined in SSKey.allKeys
      await Future.wait(
        SSKey.allKeys.map((key) {
          prints('  ✓ Deleted metadata for: $key');
          return _box.delete(key);
        }),
      );
      // for (String key in SSKey.allKeys) {
      //   try {
      //     await _box.delete(key);
      //     prints('  ✓ Deleted metadata for: $key');
      //   } catch (e) {
      //     prints('  ⚠ Error deleting metadata for $key: $e');
      //   }
      // }

      prints('✅ All sync metadata reset successfully');
    } catch (e) {
      prints('❌ Error resetting sync metadata: $e');
    }
  }
}
