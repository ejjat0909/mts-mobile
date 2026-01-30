import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Discount Repository
abstract class DiscountRepository {
  /// Get list of discounts without pagination
  Resource getDiscountList();
  
  /// Get list of discounts with pagination
  Resource getDiscountListPaginated(String page);
}
