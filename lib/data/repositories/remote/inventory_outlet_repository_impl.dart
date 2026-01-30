import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_list_response_model.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';
import 'package:mts/domain/repositories/remote/inventory_outlet_repository.dart';

class InventoryOutletRepositoryImpl implements InventoryOutletRepository {
  /// Get list of inventory outlets without pagination
  @override
  Resource getInventoryOutletList() {
    return Resource(
      modelName: InventoryOutletModel.modelName,
      url: 'inventory-outlet/list',
      parse: (response) {
        return InventoryOutletListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of inventory outlets with pagination
  @override
  Resource getInventoryOutletListPaginated(String page) {
    return Resource(
      modelName: InventoryOutletModel.modelName,
      url: 'inventory-outlet/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return InventoryOutletListResponseModel(json.decode(response.body));
      },
    );
  }
}
