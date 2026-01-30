import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Outlet Payment Type Repository
abstract class OutletPaymentTypeRepository {
  /// Get list of outlet payment types (without pagination)
  Resource getOutletPaymentTypeList();

  /// Get list of outlet payment types with pagination
  Resource getOutletPaymentTypeListPaginated(String page);
}