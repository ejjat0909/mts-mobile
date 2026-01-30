import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item_tax/item_tax_list_response_model.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/domain/repositories/remote/item_tax_repository.dart';

class ItemTaxRepositoryImpl implements ItemTaxRepository {
  /// Get list of item taxes (without pagination)
  @override
  Resource getItemTaxList() {
    return Resource(
      modelName: ItemTaxModel.modelName,
      url: 'item-taxes/list',
      parse: (response) {
        return ItemTaxListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of item taxes with pagination
  @override
  Resource getItemTaxListPaginated(String page) {
    return Resource(
      modelName: ItemTaxModel.modelName,
      url: 'item-taxes/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ItemTaxListResponseModel(json.decode(response.body));
      },
    );
  }
}
