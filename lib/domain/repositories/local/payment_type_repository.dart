import 'package:mts/data/models/payment_type/payment_type_model.dart';

abstract class LocalPaymentTypeRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single payment type record
  Future<int> insert(
    PaymentTypeModel paymentTypeModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing payment type record
  Future<int> update(
    PaymentTypeModel paymentTypeModel, {
    required bool isInsertToPending,
  });

  /// Deletes a payment type record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple payment type records at once
  Future<bool> upsertBulk(
    List<PaymentTypeModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple payment type records at once
  Future<bool> deleteBulk(
    List<PaymentTypeModel> listPTM, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PaymentTypeModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all payment type records
  Future<List<PaymentTypeModel>> getListPaymentType();

  /// Retrieves payment models by list of payment IDs
  Future<List<PaymentTypeModel>> getPaymentModelByPaymentId(
    List<String> paymentIds,
  );

  // ==================== Delete Operations ====================

  /// Deletes all payment type records
  Future<bool> deleteAll();
}
