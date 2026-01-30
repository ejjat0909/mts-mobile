import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Modifier Repository
abstract class ModifierRepository {
  /// Get list of modifiers (without pagination)
  Resource getModifierList();
  
  /// Get list of modifiers with pagination
  Resource getModifierListWithPagination(String page);
}
