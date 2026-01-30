import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Category Discount Repository
abstract class CategoryDiscountRepository {
  /// Get list of category discounts (without pagination)
  Resource getCategoryDiscountList();
  
  /// Get list of category discounts with pagination
  Resource getCategoryDiscountListPaginated(String page);
}