import 'package:mts/data/models/pos_device/pos_device_model.dart';

abstract class LocalDeviceRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single device record
  Future<int> insert(PosDeviceModel model, {required bool isInsertToPending});

  /// Updates an existing device record
  Future<int> update(PosDeviceModel model, {required bool isInsertToPending});

  /// Deletes a device record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple device records at once
  Future<bool> upsertBulk(
    List<PosDeviceModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple device records at once
  Future<bool> deleteBulk(
    List<PosDeviceModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PosDeviceModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all device records
  Future<List<PosDeviceModel>> getListDeviceModel();

  /// Retrieves a device by ID
  Future<PosDeviceModel> getDeviceById(String idDevice);

  /// Retrieves the latest device model
  Future<PosDeviceModel> getLatestDeviceModel();
}
