import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_list_response_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/domain/repositories/remote/outlet_repository.dart';

class OutletRepositoryImpl implements OutletRepository {
  /// Get list of outlets without pagination
  @override
  Resource getOutletList() {
    return Resource(
      modelName: OutletModel.modelName,
      url: 'outlets/list',
      parse: (response) {
        return OutletListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of outlets with pagination
  @override
  Resource getOutletListPaginated(String page) {
    return Resource(
      modelName: OutletModel.modelName,
      url: 'outlets/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return OutletListResponseModel(json.decode(response.body));
      },
    );
  }
}
