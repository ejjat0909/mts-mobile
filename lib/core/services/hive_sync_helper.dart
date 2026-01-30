import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/utils/log_utils.dart';

/// ================================
/// Hive Sync Helper
/// ================================
/// Helper class for Hive operations with dependency injection support.
/// All methods accept injected Box instances for better testability and explicit dependencies.
///
/// Usage:
/// ```dart
/// // Get list from injected box
/// final list = HiveSyncHelper.getListFromBox(
///   box: _hiveBox,
///   fromJson: (json) => MyModel.fromJson(json),
/// );
///
/// // Get single item
/// final item = HiveSyncHelper.getById(
///   box: _hiveBox,
///   id: 'item-123',
///   fromJson: (json) => MyModel.fromJson(json),
/// );
///
/// // Write operations - use Box methods directly:
/// await _hiveBox.put(id, data);
/// await _hiveBox.putAll(dataMap);
/// await _hiveBox.delete(id);
/// await _hiveBox.deleteAll(ids);
/// await _hiveBox.clear();
/// ```
class HiveSyncHelper {
  // Singleton instance
  static final HiveSyncHelper _instance = HiveSyncHelper._internal();
  factory HiveSyncHelper() => _instance;
  HiveSyncHelper._internal();

  /// Get a list of models from injected Hive box
  static List<T> getListFromBox<T>({
    required Box box,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    try {
      final values = box.values.whereType<Map>().toList();
      return values.map((e) => fromJson(Map.from(e))).toList();
    } catch (e) {
      LogUtils.error('Error getting list from Hive box', e);
      return [];
    }
  }

  /// Get a single model from injected Hive box by ID
  static T? getById<T>({
    required Box box,
    required String id,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    try {
      final data = box.get(id);
      if (data != null) {
        return fromJson(Map.from(data));
      }
      return null;
    } catch (e) {
      LogUtils.error('Error getting item from Hive box, id: $id', e);
      return null;
    }
  }

  /// Convert a list of models to a map suitable for Hive putAll operation
  ///
  /// Example:
  /// ```dart
  /// final dataMap = HiveSyncHelper.buildBulkDataMap(
  ///   list: models,
  ///   getId: (model) => model.id,
  ///   toJson: (model) => model.toJson(),
  /// );
  /// await _hiveBox.putAll(dataMap);
  /// ```
  static Map<dynamic, Map<dynamic, dynamic>> buildBulkDataMap<T>({
    required List<T> list,
    required String? Function(T model) getId,
    required Map<String, dynamic> Function(T model) toJson,
  }) {
    final dataMap = <dynamic, Map<dynamic, dynamic>>{};
    for (var model in list) {
      final id = getId(model);
      if (id != null) {
        dataMap[id] = toJson(model);
      }
    }
    return dataMap;
  }
}
