import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Order Option Repository
abstract class OrderOptionRepository {
  Resource getOrderOption();
  
  /// Get order options with pagination
  Resource getOrderOptionWithPagination(String page);
}
