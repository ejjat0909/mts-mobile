import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/receipt/receipt_list_response_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/domain/repositories/remote/receipt_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  /// Send receipt to email
  @override
  Resource sendReceiptToEmail(String email, String receiptId) {
    return Resource(
      url: 'send-receipt',
      data: {'receipt': receiptId, 'email': email},
      parse: (response) {
        return DefaultResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of receipts from API
  // @override
  // Resource getReceiptList() {
  //   return Resource(
  //     url: 'receipts/list',
  //     parse: (response) {
  //       return ReceiptListResponseModel(json.decode(response.body));
  //     },
  //   );
  // }

  /// Get list of receipts from API with pagination
  @override
  Resource getReceiptList(String page) {
    return Resource(
      modelName: ReceiptModel.modelName,
      url: 'receipts/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return ReceiptListResponseModel(json.decode(response.body));
      },
    );
  }
}
