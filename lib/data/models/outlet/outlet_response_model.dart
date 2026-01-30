import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/paginator_model.dart';

class OutletResponseModel extends BaseAPIResponse<OutletModel, void> {
  OutletResponseModel(super.fullJson);

  @override
  Map<String, dynamic>? dataToJson(OutletModel? data) {
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
  Null errorsToJson(errors) {
    return null;
  }

  @override
  OutletModel? jsonToData(Map<String, dynamic>? json) {
    return json!['data'] != null ? OutletModel.fromJson(json['data']) : null;
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
  void jsonToError(Map<String, dynamic> json) {
    return;
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
