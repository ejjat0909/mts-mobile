import 'package:mts/data/datasources/remote/resource.dart';

abstract class OrderOptionTaxRepository {
  /// Get list of item taxes (without pagination)

  /// Get list of item taxes with pagination
  Resource getOrderOptionTaxListPaginated(String page);
}
