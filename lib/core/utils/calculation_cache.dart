import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:mts/core/utils/log_utils.dart';

/// High-performance calculation cache with TTL and memory management
class CalculationCache {
  static final Map<String, CachedResult> _cache = <String, CachedResult>{};
  static const Duration _defaultTTL = Duration(minutes: 5);
  static const int _maxCacheSize = 1000; // Prevent memory leaks
  static final Queue<String> _accessOrder = Queue<String>();

  /// Get cached result if valid and not expired
  static CachedResult? get(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return null;
    }

    // Update access order for LRU
    _accessOrder.remove(key);
    _accessOrder.addLast(key);

    return entry;
  }

  /// Set cached result with TTL
  static void set(String key, dynamic value, [Duration? ttl]) {
    // Manage cache size (LRU eviction)
    if (_cache.length >= _maxCacheSize) {
      _evictLRU();
    }

    _cache[key] = CachedResult(
      value: value,
      expiry: DateTime.now().add(ttl ?? _defaultTTL),
    );

    // Update access order
    _accessOrder.remove(key);
    _accessOrder.addLast(key);

    if (kDebugMode) {
      prints('Cache SET: $key (size: ${_cache.length})');
    }
  }

  /// Invalidate cache entries by pattern
  static void invalidateByPattern(String pattern) {
    final keysToRemove =
        _cache.keys.where((key) => key.contains(pattern)).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      prints('Cache INVALIDATE: $pattern (${keysToRemove.length} entries)');
    }
  }

  /// Invalidate specific cache entry
  static void invalidate(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Clear all cache entries
  static void clear() {
    _cache.clear();
    _accessOrder.clear();
    prints('Cache CLEARED');
  }

  /// Clean up expired entries
  static void cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys =
        _cache.entries
            .where((entry) => now.isAfter(entry.value.expiry))
            .map((entry) => entry.key)
            .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      prints('Cache CLEANUP: ${expiredKeys.length} expired entries');
    }
  }

  /// Evict least recently used entries
  static void _evictLRU() {
    if (_accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeFirst();
      _cache.remove(oldestKey);

      if (kDebugMode) {
        prints('Cache LRU EVICT: $oldestKey');
      }
    }
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'memoryUsage': _cache.length * 100, // Rough estimate in bytes
    };
  }

  /// Generate standardized cache key
  static String generateKey({
    required String operation,
    required String itemId,
    Map<String, dynamic>? params,
  }) {
    final buffer = StringBuffer('${operation}_$itemId');

    if (params != null && params.isNotEmpty) {
      // Sort params for consistent keys
      final sortedKeys = params.keys.toList()..sort();
      for (final key in sortedKeys) {
        buffer.write('_$key:${params[key]}');
      }
    }

    return buffer.toString();
  }
}

/// Cached result wrapper with expiry
class CachedResult {
  final dynamic value;
  final DateTime expiry;
  final DateTime createdAt;

  CachedResult({required this.value, required this.expiry})
    : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiry);

  Duration get age => DateTime.now().difference(createdAt);

  @override
  String toString() =>
      'CachedResult(value: $value, age: ${age.inMilliseconds}ms, expired: $isExpired)';
}
