import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/modifier/modifier_list_response_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/domain/repositories/remote/modifier_repository.dart';

class ModifierRepositoryImpl implements ModifierRepository {
  /// Get list of modifiers (without pagination)
  @override
  Resource getModifierList() {
    return Resource(
      modelName: ModifierModel.modelName,
      url: 'modifiers/list',
      parse: (response) {
        return ModifierListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of modifiers with pagination
  @override
  Resource getModifierListWithPagination(String page) {
    return Resource(
      modelName: ModifierModel.modelName,
      url: 'modifiers/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ModifierListResponseModel(json.decode(response.body));
      },
    );
  }
}
