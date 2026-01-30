import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/discount/discount_list_response_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/domain/repositories/remote/discount_repository.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  /// Get list of discounts without pagination
  @override
  Resource getDiscountList() {
    return Resource(
      modelName: DiscountModel.modelName,
      url: 'discounts/list',
      parse: (response) {
        return DiscountListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of discounts with pagination
  @override
  Resource getDiscountListPaginated(String page) {
    return Resource(
      modelName: DiscountModel.modelName,
      url: 'discounts/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return DiscountListResponseModel(json.decode(response.body));
      },
    );
  }
}
