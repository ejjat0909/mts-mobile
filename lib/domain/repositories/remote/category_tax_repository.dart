import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Category Tax Repository
abstract class CategoryTaxRepository {
  /// Get list of category taxes (without pagination)
  Resource getCategoryTaxList();

  /// Get list of category taxes with pagination
  Resource getCategoryTaxListPaginated(String page);
}
