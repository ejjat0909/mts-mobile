/// Abstraction for cache storage operations
/// Allows different cache implementations (Hive, SharedPreferences, etc.)
abstract class ICacheStore {
  /// Store a single item in cache
  Future<void> put(String key, Map<String, dynamic> data);

  /// Store multiple items in cache
  Future<void> putAll(Map<String, Map<String, dynamic>> data);

  /// Retrieve a single item from cache
  Map<String, dynamic>? get(String key);

  /// Retrieve all items from cache
  Map<String, Map<String, dynamic>> getAll();

  /// Delete a single item from cache
  Future<void> delete(String key);

  /// Clear all items from cache
  Future<void> clear();

  /// Check if cache contains a key
  bool containsKey(String key);

  /// Get cache size
  int get length;
}
