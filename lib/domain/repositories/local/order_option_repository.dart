import 'package:mts/data/models/order_option/order_option_model.dart';

abstract class LocalOrderOptionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single order option record
  Future<int> insert(
    OrderOptionModel orderOptionModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing order option record
  Future<int> update(
    OrderOptionModel orderOptionModel, {
    required bool isInsertToPending,
  });

  /// Deletes an order option record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple order option records at once
  Future<bool> upsertBulk(
    List<OrderOptionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple order option records at once
  Future<bool> deleteBulk(
    List<OrderOptionModel> orderOptionModels, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<OrderOptionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all order option records
  Future<List<OrderOptionModel>> getListOrderOptionModel();

  /// Retrieves an order option by ID
  Future<OrderOptionModel?> getOrderOptionModelById(String idOO);

  /// Retrieves order option name by ID
  Future<String?> getOrderOptionNameById(String id);

  // ==================== Delete Operations ====================

  /// Deletes all order option records
  Future<bool> deleteAll();
}
