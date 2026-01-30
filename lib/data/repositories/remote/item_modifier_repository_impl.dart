import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item_modifier/item_modifier_list_response_model.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';
import 'package:mts/domain/repositories/remote/item_modifier_repository.dart';

class ItemModifierRepositoryImpl implements ItemModifierRepository {
  /// Get list of item modifiers without pagination
  @override
  Resource getListItemModifier() {
    return Resource(
      modelName: ItemModifierModel.modelName,
      url: 'item-modifiers/list',
      parse: (response) {
        return ItemModifierListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of item modifiers with pagination
  @override
  Resource getListItemModifierWithPagination(String page) {
    return Resource(
      modelName: ItemModifierModel.modelName,
      url: 'item-modifiers/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ItemModifierListResponseModel(json.decode(response.body));
      },
    );
  }
}
