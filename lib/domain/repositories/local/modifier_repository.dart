import 'package:mts/data/models/modifier/modifier_model.dart';

abstract class LocalModifierRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single modifier record
  Future<int> insert(
    ModifierModel modifierModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing modifier record
  Future<int> update(
    ModifierModel modifierModel, {
    required bool isInsertToPending,
  });

  /// Deletes a modifier record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple modifier records at once
  Future<bool> upsertBulk(
    List<ModifierModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple modifier records at once
  Future<bool> deleteBulk(
    List<ModifierModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ModifierModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all modifier records
  Future<List<ModifierModel>> getListModifierModel();

  /// Retrieves modifiers by list of IDs
  Future<List<ModifierModel>> getModifiersByIds(List<String?> modifierIds);

  /// Retrieves a modifier by ID
  Future<ModifierModel> getModifierById(String idModifier);

  /// Retrieves modifier list from list of modifier option IDs
  Future<List<ModifierModel>> getModifierListFromListModifierOptionIds(
    List<String> listModifierOptionIds,
  );

  // ==================== Delete Operations ====================

  /// Deletes all modifier records
  Future<bool> deleteAll();
}
