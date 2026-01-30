import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';

abstract class LocalReceiptSettingsRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single receipt settings record
  Future<int> insert(
    ReceiptSettingsModel receiptSetting, {
    required bool isInsertToPending,
  });

  /// Updates an existing receipt settings record
  Future<int> update(
    ReceiptSettingsModel receiptSetting, {
    required bool isInsertToPending,
  });

  /// Deletes a receipt settings record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple receipt settings records at once
  Future<bool> upsertBulk(
    List<ReceiptSettingsModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple receipt settings records at once
  Future<bool> deleteBulk(
    List<ReceiptSettingsModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ReceiptSettingsModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all receipt settings records
  Future<List<ReceiptSettingsModel>> getListReceiptSettings();

  // ==================== Delete Operations ====================

  /// Deletes all receipt settings records
  Future<bool> deleteAll();
}
