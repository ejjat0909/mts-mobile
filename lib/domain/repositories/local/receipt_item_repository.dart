import 'package:mts/data/models/receipt_item/receipt_item_model.dart';

abstract class LocalReceiptItemRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single receipt item record
  Future<int> insert(
    ReceiptItemModel receiptItemModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing receipt item record
  Future<int> update(
    ReceiptItemModel receiptItemModel, {
    required bool isInsertToPending,
  });

  /// Deletes a receipt item record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple receipt item records at once
  Future<bool> upsertBulk(
    List<ReceiptItemModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple receipt item records at once
  Future<bool> deleteBulk(
    List<ReceiptItemModel> receiptItems, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ReceiptItemModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all receipt item records
  Future<List<ReceiptItemModel>> getListReceiptItems();

  /// Retrieves receipt items not refunded
  Future<List<ReceiptItemModel>> getListReceiptItemsNotRefunded();

  /// Retrieves receipt items that are refunded
  Future<List<ReceiptItemModel>> getListReceiptItemsIsRefunded();

  /// Retrieves receipt items by receipt ID
  Future<List<ReceiptItemModel>> getListReceiptItemsByReceiptId(
    String idReceipt,
  );

  /// Retrieves a receipt item by ID
  Future<ReceiptItemModel?> getReceiptItemById(String idRI);

  /// Gets count of receipt items
  Future<int> getCountListReceiptItems();

  // ==================== Calculation Operations ====================

  /// Calculates total quantity not refunded sold by item
  Future<String> calcTotalQuantityNotRefundedSoldByItem();

  /// Calculates total quantity not refunded sold by measurement
  Future<String> calcTotalQuantityNotRefundedSoldByMeasurement();

  /// Calculates total quantity that is refunded
  Future<String> calcTotalQuantityIsRefunded();

  /// Calculates tax included after discount by receipt ID
  Future<double> calcTaxIncludedAfterDiscountByReceiptId(String receiptId);

  // ==================== Delete Operations ====================

  /// Deletes all receipt item records
  Future<bool> deleteAll();

  /// Deletes receipt items by receipt ID
  Future<bool> deleteByReceiptId(String idReceipt);
}
