import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Item Tax Repository
abstract class ItemTaxRepository {
  /// Get list of item taxes (without pagination)
  Resource getItemTaxList();
  
  /// Get list of item taxes with pagination
  Resource getItemTaxListPaginated(String page);
}
