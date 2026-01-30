import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_list_response_model.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/domain/repositories/remote/outlet_tax_repository.dart';

class OutletTaxRepositoryImpl implements OutletTaxRepository {
  /// Get list of outlet taxes (without pagination)
  @override
  Resource getOutletTaxList() {
    return Resource(
      modelName: OutletTaxModel.modelName,
      url: 'outlet-tax/list',
      parse: (response) {
        return OutletTaxListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of outlet taxes with pagination
  @override
  Resource getOutletTaxListPaginated(String page) {
    return Resource(
      modelName: OutletTaxModel.modelName,
      url: 'outlet-tax/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return OutletTaxListResponseModel(json.decode(response.body));
      },
    );
  }
}
