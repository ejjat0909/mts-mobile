import 'dart:convert';

import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/modifier_option/modifier_option_list_response_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/domain/repositories/remote/modifier_option_repository.dart';

class ModifierOptionRepositoryImpl implements ModifierOptionRepository {
  /// Get list of modifier options
  @override
  Resource getListModifierOption() {
    return Resource(
      modelName: ModifierOptionModel.modelName,
      url: 'modifier-options/list',
      parse: (response) {
        return ModifierOptionListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of modifier options with pagination
  @override
  Resource getModifierOptionListWithPagination(String page) {
    return Resource(
      modelName: ModifierOptionModel.modelName,
      url: 'modifier-options/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ModifierOptionListResponseModel(json.decode(response.body));
      },
    );
  }
}
