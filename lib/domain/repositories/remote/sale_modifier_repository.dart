import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Remote Sale Modifier Repository
abstract class SaleModifierRepository {
  /// Get list of sale modifiers
  ///
  /// This method returns a Resource object that can be used to fetch
  /// sale modifiers from the API.
  Resource getListSaleModifiers();
  
  /// Get list of sale modifiers with pagination
  ///
  /// This method returns a Resource object that can be used to fetch
  /// sale modifiers from the API with pagination.
  /// 
  /// @param page The page number to fetch
  Resource getListSaleModifiersWithPagination(String page);
}