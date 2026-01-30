import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Outlet Repository
abstract class OutletRepository {
  /// Get list of outlets without pagination
  Resource getOutletList();
  
  /// Get list of outlets with pagination
  Resource getOutletListPaginated(String page);
}
