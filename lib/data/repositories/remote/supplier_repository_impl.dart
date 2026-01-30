import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/supplier/supplier_list_response_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/supplier/supplier_model.dart';
import 'package:mts/domain/repositories/remote/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  /// Get list of suppliers
  @override
  Resource getSupplierList() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: SupplierModel.modelName,
      url: 'suppliers/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return SupplierListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of suppliers with pagination
  @override
  Resource getSupplierListWithPagination(String page) {
    return Resource(
      modelName: SupplierModel.modelName,
      url: 'suppliers/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return SupplierListResponseModel(json.decode(response.body));
      },
    );
  }
}
