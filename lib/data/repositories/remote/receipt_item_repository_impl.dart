import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/receipt_item/receipt_item_list_response_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/domain/repositories/remote/receipt_item_repository.dart';

class ReceiptItemRepositoryImpl implements ReceiptItemRepository {
  /// Get list of receipt items without pagination
  @override
  Resource getReceiptItem() {
    return Resource(
      modelName: ReceiptItemModel.modelName,
      url: 'receipt-items/list',
      parse: (response) {
        return ReceiptItemListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of receipt items with pagination
  @override
  Resource getReceiptItemWithPagination(String page) {
    return Resource(
      modelName: ReceiptItemModel.modelName,
      url: 'receipt-items/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ReceiptItemListResponseModel(json.decode(response.body));
      },
    );
  }
}
