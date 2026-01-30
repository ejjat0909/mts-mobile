import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/order_option/order_option_list_response_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/remote/order_option_repository.dart';

class OrderOptionRepositoryImpl implements OrderOptionRepository {
  /// Get list of order options
  @override
  Resource getOrderOption() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: OrderOptionModel.modelName,
      url: 'order-options/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return OrderOptionListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of order options with pagination
  @override
  Resource getOrderOptionWithPagination(String page) {
    return Resource(
      modelName: OrderOptionModel.modelName,
      url: 'order-options/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return OrderOptionListResponseModel(json.decode(response.body));
      },
    );
  }
}
