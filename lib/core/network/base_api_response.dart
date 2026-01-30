import 'dart:core';

import 'package:mts/core/network/http_response.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';

/// Base API response class
abstract class BaseAPIResponse<Data, Errors> {
  /// Is success flag
  bool isSuccess = false;

  /// Response message
  String message = 'Failed to fetch data from server, please try again later';

  /// Status code
  int statusCode = HttpResponse.HTTP_GONE;

  /// Response data
  Data? data;

  /// Response meta
  MetaModel? meta;

  /// Response errors
  Errors? errors;

  /// Response paginator
  PaginatorModel? paginator;

  /// Constructor
  BaseAPIResponse(Map<String, dynamic> fullJson) {
    parsing(fullJson);
  }

  /// Abstract json to data
  Data? jsonToData(Map<String, dynamic>? json);

  /// Abstract json to meta
  MetaModel? jsonToMeta(Map<String, dynamic>? json);

  /// Abstract json to errors
  Errors? jsonToError(Map<String, dynamic> json);

  /// Abstract json to paginator
  PaginatorModel? jsonToPaginator(Map<String, dynamic> json);

  /// Abstract data to json
  dynamic dataToJson(Data? data);

  /// Abstract meta to json
  dynamic metaToJson(MetaModel? meta);

  /// Abstract errors to json
  dynamic errorsToJson(Errors? errors);

  /// Abstract paginator to json
  PaginatorModel? paginatorToJson(PaginatorModel? paginatorModel);

  /// Parsing data to object
  void parsing(Map<String, dynamic> fullJson) {
    isSuccess = fullJson['is_success'] ?? false;
    message =
        fullJson['message'] ??
        (!isSuccess
            ? 'Failed to fetch data from server, please try again later'
            : '');
    statusCode =
        fullJson['status_code'] ??
        (fullJson['message'] == 'Unauthenticated.'
            ? HttpResponse.HTTP_UNAUTHORIZED
            : HttpResponse.HTTP_INTERNAL_SERVER_ERROR);
    data = fullJson['data'] != null ? jsonToData(fullJson) : null;
    meta = fullJson['meta'] != null ? jsonToMeta(fullJson) : null;
    errors = fullJson['errors'] != null ? jsonToError(fullJson) : null;
    paginator =
        fullJson['paginator'] != null ? jsonToPaginator(fullJson) : null;
  }

  /// Data to json
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataJson = <String, dynamic>{};
    dataJson['is_success'] = isSuccess;
    dataJson['message'] = message;
    dataJson['status_code'] = statusCode;
    if (data != null) {
      dataJson['data'] = dataToJson(data);
    }
    if (meta != null) {
      dataJson['meta'] = metaToJson(meta);
    }
    if (errors != null) {
      dataJson['errors'] = errorsToJson(errors);
    }
    if (paginator != null) {
      dataJson['paginator'] = paginatorToJson(paginator);
    }
    return dataJson;
  }
}
