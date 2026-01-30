import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/sale_item/sale_item_list_response_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/domain/repositories/remote/sale_item_repository.dart';

/// Implementation of the SaleItemRepository
class SaleItemRepositoryImpl implements SaleItemRepository {
  @override
  Resource getListSaleItems() {
    return Resource(
      modelName: SaleItemModel.modelName,
      url: 'sale-items/list',
      parse: (response) {
        return SaleItemListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getListSaleItemsWithPagination(String page) {
    return Resource(
      modelName: SaleItemModel.modelName,
      url: 'sale-items/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return SaleItemListResponseModel(json.decode(response.body));
      },
    );
  }
}
