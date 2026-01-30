import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Receipt Item Repository
abstract class ReceiptItemRepository {
  /// Get receipt items without pagination
  Resource getReceiptItem();

  /// Get receipt items with pagination
  Resource getReceiptItemWithPagination(String page);
}
