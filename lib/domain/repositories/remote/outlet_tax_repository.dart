import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Outlet Tax Repository
abstract class OutletTaxRepository {
  /// Get list of outlet taxes (without pagination)
  Resource getOutletTaxList();

  /// Get list of outlet taxes with pagination
  Resource getOutletTaxListPaginated(String page);
}
