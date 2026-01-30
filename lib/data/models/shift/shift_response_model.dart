import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';

class ShiftResponseModel extends BaseAPIResponse<ShiftModel, void> {
  ShiftResponseModel(super.fullJson);

  @override
  Map<String, dynamic>? dataToJson(ShiftModel? data) {
    if (this.data != null) {
      return this.data!.toJson();
    }
    return null;
  }

  @override
  Map<String, dynamic>? metaToJson(MetaModel? meta) {
    if (this.meta != null) {
      return this.meta!.toJson();
    }
    return null;
  }

  @override
  Null errorsToJson(void errors) {
    return null;
  }

  @override
  ShiftModel? jsonToData(Map<String, dynamic>? json) {
    return json!['data'] != null ? ShiftModel.fromJson(json['data']) : null;
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
    // TODO: implement jsonToPaginator
    throw UnimplementedError();
  }

  @override
  PaginatorModel? paginatorToJson(PaginatorModel? paginatorModel) {
    // TODO: implement paginatorToJson
    throw UnimplementedError();
  }
}
