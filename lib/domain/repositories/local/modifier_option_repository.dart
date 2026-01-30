import 'package:mts/data/models/modifier_option/modifier_option_model.dart';

abstract class LocalModifierOptionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single modifier option record
  Future<int> insert(
    ModifierOptionModel modifierOptionModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing modifier option record
  Future<int> update(
    ModifierOptionModel modifierOptionModel, {
    required bool isInsertToPending,
  });

  /// Deletes a modifier option record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple modifier option records at once
  Future<bool> upsertBulk(
    List<ModifierOptionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple modifier option records at once
  Future<bool> deleteBulk(
    List<ModifierOptionModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ModifierOptionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all modifier option records
  Future<List<ModifierOptionModel>> getListModifierOptionModel();

  /// Retrieves modifier options by modifier ID
  Future<List<ModifierOptionModel>> getListModifierOptionsByModifierId(
    String idModifier,
  );

  /// Retrieves modifier IDs by modifier option IDs
  Future<List<String>> getListModifierIdsByModifierOptionIds(
    List<String> modOptIds,
  );

  /// Retrieves modifier option name from list of IDs
  Future<String> getModifierOptionNameFromListIds(List<String> listIds);

  /// Retrieves modifier option models from list of IDs
  Future<List<ModifierOptionModel>> getModifierOptionModelFromListIds(
    List<String> listIds,
  );

  // ==================== Delete Operations ====================

  /// Deletes all modifier option records
  Future<bool> deleteAll();
}
