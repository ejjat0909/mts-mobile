import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item_representation/item_representation_list_response_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/domain/repositories/remote/item_representation_repository.dart';

class ItemRepresentationRepositoryImpl implements ItemRepresentationRepository {
  /// Get list of item representations
  @override
  Resource getItemRepresentation() {
    return Resource(
      modelName: ItemRepresentationModel.modelName,
      url: 'item-representations/list',
      parse: (response) {
        return ItemRepresentationListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of item representations with pagination
  @override
  Resource getItemRepresentationWithPagination(String page) {
    return Resource(
      modelName: ItemRepresentationModel.modelName,
      url: 'item-representations/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ItemRepresentationListResponseModel(json.decode(response.body));
      },
    );
  }
}
