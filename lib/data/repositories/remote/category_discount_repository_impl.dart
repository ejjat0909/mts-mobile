import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/category_discount/category_discount_list_response_model.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/domain/repositories/remote/category_discount_repository.dart';

class CategoryDiscountRepositoryImpl implements CategoryDiscountRepository {
  /// Get list of category discounts (without pagination)
  @override
  Resource getCategoryDiscountList() {
    return Resource(
      modelName: CategoryDiscountModel.modelName,
      url: 'category-discount/list',
      parse: (response) {
        return CategoryDiscountListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of category discounts with pagination
  @override
  Resource getCategoryDiscountListPaginated(String page) {
    return Resource(
      modelName: CategoryDiscountModel.modelName,
      url: 'category-discount/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return CategoryDiscountListResponseModel(json.decode(response.body));
      },
    );
  }
}
