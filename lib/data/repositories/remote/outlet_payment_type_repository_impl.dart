import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_list_response_model.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/domain/repositories/remote/outlet_payment_type_repository.dart';

class OutletPaymentTypeRepositoryImpl implements OutletPaymentTypeRepository {
  /// Get list of outlet payment types (without pagination)
  @override
  Resource getOutletPaymentTypeList() {
    return Resource(
      modelName: OutletPaymentTypeModel.modelName,
      url: 'outlet-payment-types/list',
      parse: (response) {
        return OutletPaymentTypeListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of outlet payment types with pagination
  @override
  Resource getOutletPaymentTypeListPaginated(String page) {
    return Resource(
      modelName: OutletPaymentTypeModel.modelName,
      url: 'outlet-payment-types/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return OutletPaymentTypeListResponseModel(json.decode(response.body));
      },
    );
  }
}
