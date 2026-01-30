import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Supplier Repository
abstract class SupplierRepository {
  /// Get list of suppliers
  Resource getSupplierList();

  /// Get list of suppliers with pagination
  Resource getSupplierListWithPagination(String page);
}
