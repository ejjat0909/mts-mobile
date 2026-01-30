import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';

class SaleItemResponseModel extends BaseAPIResponse<SaleItemModel, void> {
  SaleItemResponseModel(super.fullJson);

  @override
  Map<String, dynamic>? dataToJson(SaleItemModel? data) {
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
  SaleItemModel? jsonToData(Map<String, dynamic>? json) {
    return json!['data'] != null ? SaleItemModel.fromJson(json['data']) : null;
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
