import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Item Modifier Repository
abstract class ItemModifierRepository {
  /// Get list of item modifiers without pagination
  Resource getListItemModifier();
  
  /// Get list of item modifiers with pagination
  Resource getListItemModifierWithPagination(String page);
}
