import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/inventory/inventory_list_response_model.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/remote/inventory_repository.dart';

/// Implementation of [InventoryRepository]
class InventoryRepositoryImpl implements InventoryRepository {
  /// Get list of inventories
  @override
  Resource getInventoryList() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: InventoryModel.modelName,
      url: 'inventories/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return InventoryListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of inventories with pagination
  @override
  Resource getInventoryListWithPagination(String page) {
    return Resource(
      modelName: InventoryModel.modelName,
      url: 'inventories/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return InventoryListResponseModel(json.decode(response.body));
      },
    );
  }
}
