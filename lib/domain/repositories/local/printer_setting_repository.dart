import 'package:mts/data/models/printer_setting/printer_setting_model.dart';

abstract class LocalPrinterSettingRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single printer setting record
  Future<int> insert(
    PrinterSettingModel printerSetting, {
    required bool isInsertToPending,
  });

  /// Updates an existing printer setting record
  Future<int> update(
    PrinterSettingModel printerSetting, {
    required bool isInsertToPending,
  });

  /// Deletes a printer setting record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple printer setting records at once
  Future<bool> upsertBulk(
    List<PrinterSettingModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple printer setting records at once
  Future<bool> deleteBulk(
    List<PrinterSettingModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PrinterSettingModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves printer settings (optionally by outlet)
  Future<List<PrinterSettingModel>> getListPrinterSetting({
    bool isByOutlet = false,
  });

  /// Retrieves all printer settings
  Future<List<PrinterSettingModel>> getAllPrinterSettings();

  /// Retrieves printer settings for department
  Future<List<PrinterSettingModel>> getListPrinterSettingDepartment();

  /// Retrieves printer settings by device
  Future<List<PrinterSettingModel>> getListPrinterSettingByDevice({
    required bool isForThisDevice,
  });

  /// Retrieves a printer setting by ID
  Future<PrinterSettingModel?> getPrinterSettingModelById(String id);

  /// Checks if IP address exists
  Future<bool> checkIpAddressExist(String ipAddress);

  // ==================== Update Operations ====================

  /// Updates a printer setting
  Future<bool> updatePrinterSetting(PrinterSettingModel model);

  // ==================== Delete Operations ====================

  /// Deletes all printer setting records
  Future<bool> deleteAll();
}
