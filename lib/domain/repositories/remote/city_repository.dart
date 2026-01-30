import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for City Repository
abstract class CityRepository {
  /// Get list of cities
 

  /// Get list of cities with pagination
  Resource getCityListWithPagination(String page);
}