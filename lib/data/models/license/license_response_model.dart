import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/license/license_form_error_model.dart';
import 'package:mts/data/models/license/license_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';

class LicenseResponseModel
    extends BaseAPIResponse<LicenseModel, LicenseFormErrorModel> {
  LicenseResponseModel(super.fullJson);

  @override
  Map<String, dynamic>? dataToJson(LicenseModel? data) {
    if (data != null) {
      return this.data!.toJson();
    }
    return null;
  }

  @override
  Map<String, dynamic>? metaToJson(MetaModel? meta) {
    if (meta != null) {
      return this.meta!.toJson();
    }
    return null;
  }

  @override
  Map<String, dynamic>? errorsToJson(errors) {
    if (errors != null) {
      return this.errors!.toJson();
    }
    return null;
  }

  @override
  LicenseModel? jsonToData(Map<String, dynamic>? json) {
    return json!['data'] != null ? LicenseModel.fromJson(json['data']) : null;
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
  LicenseFormErrorModel? jsonToError(Map<String, dynamic> json) {
    if (json['errors'] != null) {
      return LicenseFormErrorModel.fromJson(json['errors']);
    }
    return null;
  }

  @override
  PaginatorModel? jsonToPaginator(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  PaginatorModel? paginatorToJson(PaginatorModel? paginatorModel) {
    throw UnimplementedError();
  }
}
