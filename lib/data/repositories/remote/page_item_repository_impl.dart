import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/page_item/page_item_list_response_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/domain/repositories/remote/page_item_repository.dart';
import 'package:mts/data/datasources/remote/resource.dart';

class PageItemRepositoryImpl implements PageItemRepository {
  /// Get list of page items

  /// Get list of page items with pagination
  @override
  Resource getPageItemList(String page) {
    return Resource(
      modelName: PageItemModel.modelName,
      url: 'page-items/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return PageItemListResponseModel(json.decode(response.body));
      },
    );
  }
}
