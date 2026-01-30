import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_list_response_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/domain/repositories/remote/predefined_order_repository.dart';

class PredefinedOrderRepositoryImpl implements PredefinedOrderRepository {
  /// Get list of predefined orders
  @override
  Resource getPredefinedOrderList() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: PredefinedOrderModel.modelName,
      url: 'predefined-orders/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return PredefinedOrderListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get predefined order list with pagination
  @override
  Resource getPredefinedOrderListWithPagination(String page) {
    return Resource(
      modelName: PredefinedOrderModel.modelName,
      url: 'predefined-orders/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return PredefinedOrderListResponseModel(json.decode(response.body));
      },
    );
  }
}
