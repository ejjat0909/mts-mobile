import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_list_response_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/domain/repositories/remote/sale_modifier_repository.dart';

/// Implementation of the Remote Sale Modifier Repository
class SaleModifierRepositoryImpl implements SaleModifierRepository {
  @override
  Resource getListSaleModifiers() {
    return Resource(
      modelName: SaleModifierModel.modelName,
      url: 'sale-modifiers/list',
      parse: (response) {
        return SaleModifierListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getListSaleModifiersWithPagination(String page) {
    return Resource(
      modelName: SaleModifierModel.modelName,
      url: 'sale-modifiers/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return SaleModifierListResponseModel(json.decode(response.body));
      },
    );
  }
}
