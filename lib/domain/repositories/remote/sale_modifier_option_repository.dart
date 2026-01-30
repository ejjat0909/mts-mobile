import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Remote Sale Modifier Option Repository
abstract class SaleModifierOptionRepository {
  /// Get list of sale modifier options
  ///
  /// This method returns a Resource object that can be used to fetch
  /// sale modifier options from the API.
  Resource getListSaleModifierOptions();
  
  /// Get list of sale modifier options with pagination
  ///
  /// This method returns a Resource object that can be used to fetch
  /// sale modifier options from the API with pagination.
  /// 
  /// @param page The page number to fetch
  Resource getListSaleModifierOptionsWithPagination(String page);
}