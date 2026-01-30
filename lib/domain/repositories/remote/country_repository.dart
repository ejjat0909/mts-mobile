import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Country Repository
abstract class CountryRepository {
  /// Get list of countries
  Resource getCountryList();

  /// Get list of countries with pagination
  Resource getCountryListWithPagination(String page);
}