import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/city/city_list_response_model.dart';
import 'package:mts/data/models/city/city_model.dart';
import 'package:mts/domain/repositories/remote/city_repository.dart';

/// Implementation of [CityRepository]
class CityRepositoryImpl implements CityRepository {
  /// Get list of cities
 

  /// Get list of cities with pagination
  @override
  Resource getCityListWithPagination(String page) {
    return Resource(
      modelName: CityModel.modelName,
      url: 'world/cities/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return CityListResponseModel(json.decode(response.body));
      },
    );
  }
}
