import 'dart:convert';

import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/sale_variant_option/sale_variant_option_list_response_model.dart';
import 'package:mts/data/models/sale_variant_option/sale_variant_option_model.dart';
import 'package:mts/domain/repositories/remote/sale_variant_option_repository.dart';

/// Implementation of Remote Sale Variant Option Repository
class SaleVariantOptionRepositoryImpl implements SaleVariantOptionRepository {
  @override
  Resource getSaleVariantOptionList() {
    return Resource(
      modelName: SaleVariantOptionModel.modelName,
      url: 'sale-variant-options/list',
      parse: (response) {
        return SaleVariantOptionListResponseModel(json.decode(response.body));
      },
    );
  }
}
