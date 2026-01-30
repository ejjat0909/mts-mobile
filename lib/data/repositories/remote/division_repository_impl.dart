import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/division/division_list_response_model.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/domain/repositories/remote/division_repository.dart';

/// Implementation of [DivisionRepository]
class DivisionRepositoryImpl implements DivisionRepository {
  /// Get list of divisions
  @override
  Resource getDivisionList() {
    return Resource(
      modelName: DivisionModel.modelName,
      url: 'world/divisions/list',
      parse: (response) {
        return DivisionListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of divisions with pagination
  @override
  Resource getDivisionListWithPagination(String page) {
    return Resource(
      modelName: DivisionModel.modelName,
      url: 'world/divisions/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return DivisionListResponseModel(json.decode(response.body));
      },
    );
  }
}
