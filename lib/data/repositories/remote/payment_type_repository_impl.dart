import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/payment_type/payment_type_list_response_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/domain/repositories/remote/payment_type_repository.dart';

class PaymentTypeRepositoryImpl implements PaymentTypeRepository {
  /// Get list of payment types
  @override
  Resource getPaymentType() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: PaymentTypeModel.modelName,
      url: 'payment-types/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return PaymentTypeListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of payment types with pagination
  @override
  Resource getPaymentTypeWithPagination(String page) {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: PaymentTypeModel.modelName,
      url: 'payment-types/list',
      params: {'outlet': outletModel.id, 'page': page, 'take': take},
      parse: (response) {
        return PaymentTypeListResponseModel(json.decode(response.body));
      },
    );
  }
}
