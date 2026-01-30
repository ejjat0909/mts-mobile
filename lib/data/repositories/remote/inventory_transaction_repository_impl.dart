import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_list_response_model.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/remote/inventory_transaction_repository.dart';

/// Implementation of [InventoryTransactionRepository]
class InventoryTransactionRepositoryImpl
    implements InventoryTransactionRepository {
  /// Get list of inventory transactions
  @override
  Resource getInventoryTransactionList() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: InventoryTransactionModel.modelName,
      url: 'inventory-transactions/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return InventoryTransactionListResponseModel(
          json.decode(response.body),
        );
      },
    );
  }

  /// Get list of inventory transactions with pagination
  @override
  Resource getInventoryTransactionListWithPagination(String page) {
    return Resource(
      modelName: InventoryTransactionModel.modelName,
      url: 'inventory-transactions/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return InventoryTransactionListResponseModel(
          json.decode(response.body),
        );
      },
    );
  }
}
