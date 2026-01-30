import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/data/datasources/local/storage_keys.dart';

/// Local storage datasource for storing data locally
class StorageDatasource {
  final SecureStorageApi _secureStorage;

  /// Constructor with dependency injection
  StorageDatasource({required SecureStorageApi secureStorage})
    : _secureStorage = secureStorage;

  /// Read string value from secure storage
  Future<String> readString(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Write string value to secure storage
  Future<bool> writeString(String key, String value) async {
    return await _secureStorage.write(key, value);
  }

  /// Read object from secure storage
  Future<dynamic> readObject(String key) async {
    return await _secureStorage.readObject(key);
  }

  /// Save object to secure storage
  Future<void> saveObject(String key, dynamic value) async {
    await _secureStorage.saveObject(key, value);
  }

  /// Delete value from secure storage
  Future<bool> delete(String key) async {
    return await _secureStorage.delete(key: key);
  }

  /// Delete all values from secure storage
  // Future<bool> deleteAll() async {
  //   return await _secureStorage.deleteAll();
  // }

  /// Save multiple objects to secure storage
  // Future<void> saveMultipleObjects(List<String> keys, dynamic value) async {
  //   await _secureStorage.saveMultipleObjects(keys, value);
  // }

  /// Get token from secure storage
 

  /// Save token to secure storage
  

  /// Delete token from secure storage
  Future<bool> deleteToken() async {
    return await _secureStorage.deleteToken();
  }

  /// Clear all meta data
  Future<void> clearAllMetaData() async {
    for (String key in StorageKeys.allKeys) {
      await delete(key);
    }
  }

  /// Save meta data
  Future<void> saveMetaData(String key, List<dynamic> data) async {
    await saveObject(key, data);
  }

  /// Get meta data
  Future<List<dynamic>> getMetaData(String key) async {
    final data = await readObject(key);
    return data ?? [];
  }

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await saveObject('user_data', userData);
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await readObject('user_data');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Save business data
  Future<void> saveBusinessData(Map<String, dynamic> businessData) async {
    await saveObject('business_data', businessData);
  }

  /// Get business data
  Future<Map<String, dynamic>?> getBusinessData() async {
    final data = await readObject('business_data');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
}
