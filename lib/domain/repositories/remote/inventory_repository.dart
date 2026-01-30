import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Inventory Repository
abstract class InventoryRepository {
  /// Get list of inventories
  Resource getInventoryList();

  /// Get list of inventories with pagination
  Resource getInventoryListWithPagination(String page);
}
