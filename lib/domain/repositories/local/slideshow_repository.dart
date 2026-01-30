import 'package:mts/data/models/slideshow/slideshow_model.dart';

abstract class LocalSlideshowRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single slideshow record
  Future<Map<String, dynamic>> insert(
    SlideshowModel secondDisplay, {
    required bool isInsertToPending,
  });

  /// Updates an existing slideshow record
  Future<int> update(
    SlideshowModel secondDisplay, {
    required bool isInsertToPending,
  });

  /// Deletes a slideshow record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple slideshow records at once
  Future<bool> upsertBulk(
    List<SlideshowModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple slideshow records at once
  Future<bool> deleteBulk(
    List<SlideshowModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<SlideshowModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves the latest model
  Future<Map<String, dynamic>> getLatestModel();

  /// Retrieves a slideshow by ID
  Future<SlideshowModel> getModelById(String id);

  // ==================== Delete Operations ====================

  /// Deletes all slideshow records
  Future<bool> deleteAll();
}
