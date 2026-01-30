import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/interfaces/i_cache_store.dart';

/// Hive implementation of ICacheStore
/// Provides interface abstraction over HiveSyncHelper pattern
class HiveCacheStore implements ICacheStore {
  final Box<Map> _box;

  HiveCacheStore(this._box);

  @override
  Future<void> put(String key, Map<String, dynamic> data) async {
    await _box.put(key, data);
  }

  @override
  Future<void> putAll(Map<String, Map<String, dynamic>> data) async {
    // Use HiveSyncHelper pattern - putAll expects Map<dynamic, Map<dynamic, dynamic>>
    final hiveMap = <dynamic, Map<dynamic, dynamic>>{};
    data.forEach((key, value) => hiveMap[key] = value);
    await _box.putAll(hiveMap);
  }

  @override
  Map<String, dynamic>? get(String key) {
    final value = _box.get(key);
    return value != null ? Map<String, dynamic>.from(value) : null;
  }

  @override
  Map<String, Map<String, dynamic>> getAll() {
    final result = <String, Map<String, dynamic>>{};
    for (var key in _box.keys) {
      final value = _box.get(key);
      if (value != null) {
        result[key.toString()] = Map<String, dynamic>.from(value);
      }
    }
    return result;
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  bool containsKey(String key) {
    return _box.containsKey(key);
  }

  @override
  int get length => _box.length;

  /// Get the underlying Box instance for direct Hive operations if needed
  Box<Map> get box => _box;
}
