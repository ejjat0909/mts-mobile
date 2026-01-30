import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/sale/sale_list_response_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/domain/repositories/remote/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  @override
  Resource getListSale() {
    return Resource(
      modelName: SaleModel.modelName,
      url: 'sales/list',
      parse: (response) {
        return SaleListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getListSaleWithPagination(String page) {
    return Resource(
      modelName: SaleModel.modelName,
      url: 'sales/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return SaleListResponseModel(json.decode(response.body));
      },
    );
  }
}
