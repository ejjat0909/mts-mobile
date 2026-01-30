import 'package:mts/data/models/feature/feature_model.dart';

abstract class LocalFeatureRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single feature record
  Future<int> insert(
    FeatureModel featureModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing feature record
  Future<int> update(
    FeatureModel featureModel, {
    required bool isInsertToPending,
  });

  /// Deletes a feature record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple feature records at once
  Future<bool> upsertBulk(
    List<FeatureModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple feature records at once
  Future<bool> deleteBulk(
    List<FeatureModel> listFeatures, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<FeatureModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all feature records
  Future<List<FeatureModel>> getListFeatures();

  // ==================== Delete Operations ====================

  /// Deletes all feature records
  Future<bool> deleteAll();
}
