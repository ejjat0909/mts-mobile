import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/item/item_list_response_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/domain/repositories/remote/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  /// Get list of items
  @override
  Resource getItemList(String page) {
    return Resource(
      modelName: ItemModel.modelName,
      url: 'items/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ItemListResponseModel(json.decode(response.body));
      },
    );
  }
}
