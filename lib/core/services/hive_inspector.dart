import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/log_utils.dart';

/// Utility class for inspecting and debugging Hive boxes
/// Similar to SQLite's databaseList() but for Hive
class HiveInspector {
  /// Get all box names and their contents
  static Future<Map<String, dynamic>> inspectAllBoxes() async {
    final result = <String, dynamic>{};

    for (final boxName in HiveBoxManager.allBoxNames) {
      try {
        final box = Hive.box<Map>(boxName);
        result[boxName] = {
          'count': box.length,
          'keys': box.keys.toList(),
          'isEmpty': box.isEmpty,
        };
      } catch (e) {
        result[boxName] = {'error': e.toString()};
      }
    }

    return result;
  }

  /// Get detailed contents of a specific box
  static Future<List<Map<String, dynamic>>> getBoxContents(
    String boxName,
  ) async {
    try {
      final box = Hive.box<Map>(boxName);
      final contents = <Map<String, dynamic>>[];

      for (int i = 0; i < box.length; i++) {
        try {
          final value = box.getAt(i);
          contents.add({'key': box.keyAt(i), 'value': value, 'index': i});
        } catch (e) {
          contents.add({
            'key': box.keyAt(i),
            'error': 'Failed to read value: $e',
            'index': i,
          });
        }
      }

      return contents;
    } catch (e) {
      LogUtils.error('Error getting box contents for $boxName: $e');
      return [];
    }
  }

  /// Get specific item from a box by key
  static dynamic getBoxItem(String boxName, dynamic key) {
    try {
      final box = Hive.box<Map>(boxName);
      return box.get(key);
    } catch (e) {
      LogUtils.error('Error getting item from $boxName with key $key: $e');
      return null;
    }
  }

  /// Print formatted statistics
  static Future<void> printStatistics() async {
    final stats = await HiveInitHelper.getCacheStatistics();
    final totalSize = await HiveInitHelper.getTotalCacheSize();

    prints('\n╔════════════════════════════════════╗');
    prints('║      HIVE CACHE STATISTICS        ║');
    prints('╚════════════════════════════════════╝');

    int maxLength = stats.keys.fold(
      0,
      (max, key) => key.length > max ? key.length : max,
    );

    stats.forEach((boxName, count) {
      final padding = ' ' * (maxLength - boxName.length);
      prints('  $boxName$padding : ${count.toString().padLeft(6)} items');
    });

    prints('  ${'-' * (maxLength + 12)}');
    prints(
      '  Total${''.padRight(maxLength - 5)} : ${totalSize.toString().padLeft(6)} items',
    );
    prints('');
  }

  /// Print contents of a specific box (formatted)
  static Future<void> printBoxContents(String boxName, {int limit = 10}) async {
    try {
      final box = Hive.box<Map>(boxName);

      prints('\n╔════════════════════════════════════╗');
      prints('║  BOX: $boxName');
      prints('║  Items: ${box.length}');
      prints('╚════════════════════════════════════╝');

      int count = 0;
      for (int i = 0; i < box.length && count < limit; i++) {
        try {
          final key = box.keyAt(i);
          final value = box.getAt(i);

          prints('\n  [$count] Key: $key');
          prints('      Value: ${_formatValue(value)}');

          count++;
        } catch (e) {
          prints('  [!] Error reading entry: $e');
        }
      }

      if (box.length > limit) {
        prints('\n  ... and ${box.length - limit} more items');
      }

      prints('');
    } catch (e) {
      LogUtils.error('Error printing box contents for $boxName: $e');
    }
  }

  /// Delete an item from a specific box
  static Future<bool> deleteBoxItem(String boxName, dynamic key) async {
    try {
      final box = Hive.box<Map>(boxName);
      await box.delete(key);
      LogUtils.info('Deleted key $key from box $boxName');
      return true;
    } catch (e) {
      LogUtils.error('Error deleting item from $boxName: $e');
      return false;
    }
  }

  /// Clear a specific box
  static Future<bool> clearBox(String boxName) async {
    try {
      final box = Hive.box<Map>(boxName);
      await box.clear();
      LogUtils.info('Cleared box $boxName');
      return true;
    } catch (e) {
      LogUtils.error('Error clearing box $boxName: $e');
      return false;
    }
  }

  /// Search for items matching a predicate in a box
  static Future<List<Map<String, dynamic>>> searchBox(
    String boxName,
    bool Function(dynamic value) predicate,
  ) async {
    try {
      final box = Hive.box<Map>(boxName);
      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < box.length; i++) {
        try {
          final value = box.getAt(i);
          if (predicate(value)) {
            results.add({'key': box.keyAt(i), 'value': value, 'index': i});
          }
        } catch (e) {
          // Skip items that can't be read
        }
      }

      return results;
    } catch (e) {
      LogUtils.error('Error searching box $boxName: $e');
      return [];
    }
  }

  /// Format value for display
  static String _formatValue(dynamic value) {
    if (value == null) return 'null';

    if (value is Map) {
      return 'Map with ${value.length} entries';
    }

    if (value is List) {
      return 'List with ${value.length} items';
    }

    if (value is String) {
      return value.length > 50 ? '${value.substring(0, 50)}...' : value;
    }

    return value.toString();
  }

  /// Get a summary of all boxes
  static Future<String> getSummary() async {
    final stats = await HiveInitHelper.getCacheStatistics();
    final totalSize = await HiveInitHelper.getTotalCacheSize();

    final buffer = StringBuffer();
    buffer.writeln('=== HIVE CACHE SUMMARY ===');
    buffer.writeln('Total boxes: ${stats.length}');
    buffer.writeln('Total items: $totalSize');
    buffer.writeln('\nBoxes:');

    stats.forEach((boxName, count) {
      buffer.writeln('  - $boxName: $count items');
    });

    return buffer.toString();
  }
}
