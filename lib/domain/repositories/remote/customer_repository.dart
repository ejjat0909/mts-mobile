import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Customer Repository
abstract class CustomerRepository {
  /// Get list of customers
  Resource getCustomerList();
  
  /// Get list of customers with pagination
  Resource getCustomerListWithPagination(String page);
}
