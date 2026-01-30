import 'dart:convert';

import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/feature/feature_list_response_model.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/domain/repositories/remote/feature_repository.dart';

/// Implementation of [RemoteFeatureRepository]
class RemoteFeatureRepositoryImpl implements RemoteFeatureRepository {
  @override
  Resource getFeatureList() {
    return Resource(
      modelName: FeatureModel.modelName,
      url: 'features/list',
      parse: (response) {
        return FeatureListResponseModel(json.decode(response.body));
      },
    );
  }
}
