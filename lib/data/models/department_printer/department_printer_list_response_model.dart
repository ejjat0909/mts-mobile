import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';

class DepartmentPrinterListResponseModel
    extends BaseAPIResponse<List<DepartmentPrinterModel>, void> {
  DepartmentPrinterListResponseModel(super.fullJson);

  @override
  List<Map<String, dynamic>>? dataToJson(List<DepartmentPrinterModel>? data) {
    if (this.data != null) {
      return this.data?.map((v) => v.toJson()).toList();
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
  Null errorsToJson(void errors) {
    return null;
  }

  @override
  List<DepartmentPrinterModel>? jsonToData(Map<String, dynamic>? json) {
    if (json != null) {
      data = [];

      json['data'].forEach((v) {
        data!.add(DepartmentPrinterModel.fromJson(v));
      });

      return data!;
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
  void jsonToError(Map<String, dynamic> json) {
    return;
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
