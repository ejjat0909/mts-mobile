import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_list_response_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/domain/repositories/remote/sale_modifier_option_repository.dart';

/// Implementation of the Remote Sale Modifier Option Repository
class SaleModifierOptionRepositoryImpl implements SaleModifierOptionRepository {
  @override
  Resource getListSaleModifierOptions() {
    return Resource(
      modelName: SaleModifierOptionModel.modelName,
      url: 'sale-modifier-options/list',
      parse: (response) {
        return SaleModifierOptionListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getListSaleModifierOptionsWithPagination(String page) {
    return Resource(
      modelName: SaleModifierOptionModel.modelName,
      url: 'sale-modifier-options/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return SaleModifierOptionListResponseModel(json.decode(response.body));
      },
    );
  }
}
