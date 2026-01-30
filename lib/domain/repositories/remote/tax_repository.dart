import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Tax Repository
abstract class TaxRepository {
  /// Get tax list with pagination
  Resource getTaxList(String page);
}
