import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Receipt Repository
abstract class ReceiptRepository {
  /// Send receipt to email
  Resource sendReceiptToEmail(String email, String receiptId);

  /// Get list of receipts from API
  // Resource getReceiptList();

  /// Get list of receipts from API with pagination
  Resource getReceiptList(String page);
}
