import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/category_tax/category_tax_list_response_model.dart';
import 'package:mts/domain/repositories/remote/category_tax_repository.dart';

class CategoryTaxRepositoryImpl implements CategoryTaxRepository {
  /// Get list of category taxes (without pagination)
  @override
  Resource getCategoryTaxList() {
    return Resource(
      modelName: CategoryModel.modelName,
      url: 'category-tax/list',
      parse: (response) {
        return CategoryTaxListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of category taxes with pagination
  @override
  Resource getCategoryTaxListPaginated(String page) {
    return Resource(
      modelName: CategoryModel.modelName,
      url: 'category-tax/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return CategoryTaxListResponseModel(json.decode(response.body));
      },
    );
  }
}
