import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/category/category_model.dart';

/// Interface for Remote Category Repository
abstract class CategoryRepository {
  /// Get list of categories with pagination
  Resource getCategoryList(String page);

  /// Get list of categories with pagination
  Future<List<CategoryModel>> fetchAllPaginated();
}
