import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Remote Inventory Outlet Repository
abstract class InventoryOutletRepository {
  /// Get list of inventory outlets without pagination
  Resource getInventoryOutletList();

  /// Get list of inventory outlets with pagination
  Resource getInventoryOutletListPaginated(String page);
}