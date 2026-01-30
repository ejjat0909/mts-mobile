import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';

abstract class LocalDiscountOutletRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates a discount outlet record
  Future<int> upsert(
    DiscountOutletModel row, {
    required bool isInsertToPending,
  });

  /// Deletes a discount outlet pivot
  Future<int> deletePivot(
    DiscountOutletModel discountOutletModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple discount outlet records at once
  Future<bool> upsertBulk(
    List<DiscountOutletModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple discount outlet records at once
  Future<bool> deleteBulk(
    List<DiscountOutletModel> listDiscountOutlet, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<DiscountOutletModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all discount outlet records
  Future<List<DiscountOutletModel>> getListDiscountOutlet();

  // ==================== Delete Operations ====================

  /// Deletes all discount outlet records
  Future<bool> deleteAll();

  /// Deletes records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
