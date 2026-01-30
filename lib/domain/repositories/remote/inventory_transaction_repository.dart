import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Inventory Transaction Repository (Remote/API)
abstract class InventoryTransactionRepository {
  /// Get list of inventory transactions
  Resource getInventoryTransactionList();

  /// Get list of inventory transactions with pagination
  Resource getInventoryTransactionListWithPagination(String page);
}