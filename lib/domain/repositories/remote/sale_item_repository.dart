import 'package:mts/data/datasources/remote/resource.dart';

/// Repository for handling remote sale item operations
abstract class SaleItemRepository {
  /// Get list of sale items from API
  Resource getListSaleItems();
  
  /// Get list of sale items from API with pagination
  Resource getListSaleItemsWithPagination(String page);
}

