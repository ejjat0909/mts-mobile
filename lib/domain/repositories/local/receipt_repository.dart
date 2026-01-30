import 'package:flutter/material.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';

abstract class LocalReceiptRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single receipt record
  Future<int> insert(ReceiptModel receipt, {required bool isInsertToPending});

  /// Updates an existing receipt record
  Future<int> update(ReceiptModel receipt, {required bool isInsertToPending});

  /// Deletes a receipt record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple receipt records at once
  Future<bool> upsertBulk(
    List<ReceiptModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple receipt records at once
  Future<bool> deleteBulk(
    List<ReceiptModel> receipts, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ReceiptModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all receipt records
  Future<List<ReceiptModel>> getListReceiptModel();

  /// Retrieves receipt records by shift ID
  Future<List<ReceiptModel>> getListReceiptModelByShiftId();

  /// Retrieves a receipt by ID
  Future<ReceiptModel?> getReceiptModelFromId(String receiptId);

  /// Retrieves the latest receipt
  Future<ReceiptModel> getLatestReceiptModel();

  /// Searches receipts by ID from database
  Future<List<ReceiptModel>> searchReceiptIDFromDb(
    String query,
    DateTimeRange? dateRange,
    int page,
    int pageSize,
    String? paymentType,
    String? orderOption,
  );

  // ==================== Calculation Operations ====================

  /// Calculates payable amount not refunded
  Future<double> calcPayableAmountNotRefunded();

  /// Calculates payable amount refunded
  Future<double> calcPayableAmountRefunded();

  /// Calculates all amount refunded
  Future<double> calcAllAmountRefunded();

  /// Calculates gross sales
  Future<String> calcGrossSales();

  /// Calculates net sales
  Future<String> calcNetSales();

  /// Calculates adjustment
  Future<String> calcAdjustment();

  /// Calculates total discount
  Future<String> calcTotalDiscount();

  /// Calculates total tax
  Future<String> calcTotalTax();

  /// Calculates total cash rounding
  Future<String> calcTotalCashRounding();

  // ==================== Utility Operations ====================

  /// Formats date time
  String formatDateTime(DateTime dateTime);

  // ==================== Delete Operations ====================

  /// Deletes all receipt records
  Future<bool> deleteAll();
}
