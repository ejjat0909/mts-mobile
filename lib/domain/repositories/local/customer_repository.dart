import 'package:mts/data/models/customer/customer_model.dart';

abstract class LocalCustomerRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single customer record
  Future<int> insert(
    CustomerModel customerModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing customer record
  Future<int> update(
    CustomerModel customerModel, {
    required bool isInsertToPending,
  });

  /// Deletes a customer record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple customer records at once
  Future<bool> upsertBulk(
    List<CustomerModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple customer records at once
  Future<bool> deleteBulk(
    List<CustomerModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<CustomerModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all customer records
  Future<List<CustomerModel>> getListCustomerModel();

  /// Retrieves a customer by ID
  Future<CustomerModel?> getCustomerModelById(String customerId);

  // ==================== Delete Operations ====================

  /// Deletes all customer records
  Future<bool> deleteAll();
}
