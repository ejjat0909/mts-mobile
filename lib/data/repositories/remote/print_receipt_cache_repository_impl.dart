import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_list_response_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/domain/repositories/remote/print_receipt_cache_repository.dart';

class PrintReceiptCacheRepositoryImpl implements PrintReceiptCacheRepository {
  @override
  Resource getPrintReceiptCacheList() {
    return Resource(
      modelName: PrintReceiptCacheModel.modelName,
      url: 'print-receipt-cache/list',
      parse: (response) {
        return PrintReceiptCacheListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getPrintReceiptCacheListPaginated(String page) {
    return Resource(
      modelName: PrintReceiptCacheModel.modelName,
      url: 'print-receipt-cache/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return PrintReceiptCacheListResponseModel(json.decode(response.body));
      },
    );
  }
}
