import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';

abstract class LocalOutletPaymentTypeRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates an outlet payment type record
  Future<int> upsert(
    OutletPaymentTypeModel outletPaymentTypeModel, {
    required bool isInsertToPending,
  });

  /// Deletes an outlet payment type pivot
  Future<int> deletePivot(
    OutletPaymentTypeModel outletPaymentTypeModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple outlet payment type records at once
  Future<bool> upsertBulk(
    List<OutletPaymentTypeModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple outlet payment type records at once
  Future<bool> deleteBulk(
    List<OutletPaymentTypeModel> listOutletPaymentType, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<OutletPaymentTypeModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all outlet payment type records
  Future<List<OutletPaymentTypeModel>> getListOutletPaymentType();

  /// Retrieves all outlet payment type models
  Future<List<OutletPaymentTypeModel>> getListOutletPaymentTypeModel();

  /// Retrieves payment type models by outlet ID
  Future<List<PaymentTypeModel>> getPaymentTypeModelsByOutletId(
    String idOutlet,
  );

  // ==================== Delete Operations ====================

  /// Deletes all outlet payment type records
  Future<bool> deleteAll();

  /// Deletes records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
