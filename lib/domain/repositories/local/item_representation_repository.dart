import 'package:mts/data/models/item_representation/item_representation_model.dart';

abstract class LocalItemRepresentationRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single item representation record
  Future<int> insert(
    ItemRepresentationModel itemRepresentationModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing item representation record
  Future<int> update(
    ItemRepresentationModel itemRepresentationModel, {
    required bool isInsertToPending,
  });

  /// Deletes an item representation record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple item representation records at once
  Future<bool> upsertBulk(
    List<ItemRepresentationModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple item representation records at once
  Future<bool> deleteBulk(
    List<ItemRepresentationModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ItemRepresentationModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all item representation records
  Future<List<ItemRepresentationModel>> getListItemRepresentationModel();

  /// Retrieves image path by item representation ID
  Future<String?> getImagePathById(String idIR);

  // ==================== Delete Operations ====================

  /// Deletes all item representation records
  Future<bool> deleteAll();
}
