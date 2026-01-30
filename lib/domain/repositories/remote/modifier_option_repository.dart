import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Modifier Option Repository
abstract class ModifierOptionRepository {
  Resource getListModifierOption();

  Resource getModifierOptionListWithPagination(String page);
}
