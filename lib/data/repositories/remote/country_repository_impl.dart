import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/country/country_list_response_model.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/domain/repositories/remote/country_repository.dart';

/// Implementation of [CountryRepository]
class CountryRepositoryImpl implements CountryRepository {
  /// Get list of countries
  @override
  Resource getCountryList() {
    return Resource(
      modelName: CountryModel.modelName,
      url: 'world/countries/list',
      parse: (response) {
        return CountryListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of countries with pagination
  @override
  Resource getCountryListWithPagination(String page) {
    return Resource(
      modelName: CountryModel.modelName,
      url: 'world/countries/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return CountryListResponseModel(json.decode(response.body));
      },
    );
  }
}
