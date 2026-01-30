import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/forgot_password/forgot_password_form_error_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';

class ForgotPasswordResponsemodel
    extends BaseAPIResponse<dynamic, ForgotPasswordFormErrorModel> {
  ForgotPasswordResponsemodel(super.fullJson);

  @override
  Null dataToJson(data) {
    return null;
  }

  @override
  Null metaToJson(meta) {
    return null;
  }

  @override
  Null errorsToJson(errors) {
    return null;
  }

  @override
  dynamic jsonToData(Map<String, dynamic>? json) {
    if (json != null) {
      return json['data'];
    }
  }

  @override
  ForgotPasswordFormErrorModel? jsonToError(Map<String, dynamic> json) {
    if (json['errors'] != null) {
      return ForgotPasswordFormErrorModel.fromJson(json['errors']);
    }
    return null;
  }

  @override
  MetaModel? jsonToMeta(Map<String, dynamic>? json) {
    if (json != null) {
      if (json['meta'] != null) {
        return MetaModel.fromJson(json['meta']);
      }
    }
    return null;
  }

  @override
  PaginatorModel? jsonToPaginator(Map<String, dynamic> json) {
    return null;
  }

  @override
  PaginatorModel? paginatorToJson(PaginatorModel? paginatorModel) {
    return null;
  }
}
