import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Division Repository
abstract class DivisionRepository {
  /// Get list of divisions
  Resource getDivisionList();

  /// Get list of divisions with pagination
  Resource getDivisionListWithPagination(String page);
}