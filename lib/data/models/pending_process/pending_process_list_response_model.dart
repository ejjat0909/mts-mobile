import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';
import 'package:mts/data/models/pending_process/pending_process_data_model.dart';

class PendingProcessListResponseModel
    extends BaseAPIResponse<PendingProcessDataModel, dynamic> {
  PendingProcessListResponseModel(super.fullJson);

  @override
  Map<String, dynamic>? dataToJson(PendingProcessDataModel? data) {
    if (this.data != null) {
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
  dynamic errorsToJson(dynamic errors) {
    return errors;
  }

  @override
  PendingProcessDataModel? jsonToData(Map<String, dynamic>? json) {
    if (json != null && json['data'] != null) {
      return PendingProcessDataModel.fromJson(json['data']);
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
  dynamic jsonToError(Map<String, dynamic> json) {
    return json['errors'];
  }

  @override
  PaginatorModel? jsonToPaginator(Map<String, dynamic> json) {
    // Convert json["paginator"] data to PaginatorModel
    if (json['paginator'] != null) {
      return PaginatorModel.fromJson(json['paginator']);
    }
    return null;
  }

  @override
  PaginatorModel? paginatorToJson(PaginatorModel? paginatorModel) {
    return null;
  }
}
