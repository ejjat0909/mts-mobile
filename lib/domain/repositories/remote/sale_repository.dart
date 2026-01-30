import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Sale Repository
abstract class SaleRepository {
  Resource getListSale();
  
  /// Get list of sales with pagination support
  Resource getListSaleWithPagination(String page);
}
