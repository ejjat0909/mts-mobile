import 'dart:convert';

import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/feature/feature_company_list_response_model.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/domain/repositories/remote/feature_company_repository.dart';

/// Implementation of [RemoteFeatureCompanyRepository]
class RemoteFeatureCompanyRepositoryImpl implements RemoteFeatureCompanyRepository {
  @override
  Resource getFeatureCompanyList() {
    return Resource(
      modelName: FeatureCompanyModel.modelName,
      url: 'feature-companies/list',
      parse: (response) {
        return FeatureCompanyListResponseModel(json.decode(response.body));
      },
    );
  }
}