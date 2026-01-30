import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_list_response_model.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/domain/repositories/remote/order_option_tax_repository.dart';

class OrderOptionTaxRepositoryImpl implements OrderOptionTaxRepository {
  /// Get list of item taxes (without pagination)

  /// Get list of item taxes with pagination
  @override
  Resource getOrderOptionTaxListPaginated(String page) {
    return Resource(
      modelName: OrderOptionTaxModel.modelName,
      url: 'order-option-tax/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return OrderOptionTaxListResponseModel(json.decode(response.body));
      },
    );
  }
}
