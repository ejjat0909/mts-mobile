import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Predefined Order Repository
abstract class PredefinedOrderRepository {
  Resource getPredefinedOrderList();
  
  /// Get predefined order list with pagination
  Resource getPredefinedOrderListWithPagination(String page);
}
