import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/customer/customer_list_response_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/remote/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  /// Get list of customers
  @override
  Resource getCustomerList() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: CustomerModel.modelName,
      url: 'customers/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return CustomerListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of customers with pagination
  @override
  Resource getCustomerListWithPagination(String page) {
    return Resource(
      modelName: CustomerModel.modelName,
      url: 'customers/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return CustomerListResponseModel(json.decode(response.body));
      },
    );
  }
}
